#!/bin/bash
# Shared body validator for gitgit commit-discipline enforcement.
# Called by the PreToolUse:Bash guard (commit-body.sh), the git-native
# commit-msg hook, and the prepare-commit-msg hook.
#
# Interface:
#   validate_body <commit-msg-file-path>
#     exit 0: validated OK, nothing on stdout
#     exit 1: violation; diagnostic on stderr (format: "<code>: <detail>")
#     exit 2: file unreadable or not a commit message; skip non-blocking
#
#   validate_body_classify_skip <subject>
#     exit 0: subject matches a skip pattern (Merge / Revert / fixup! / squash! / amend!)
#     exit 1: subject does not match any skip pattern

# Note: no "set -euo pipefail" here. This file is sourced as a library by
# dispatch.sh, git hooks, and test harnesses. Caller shells already control
# their own errexit/pipefail; setting it here would cause "read -r" at EOF
# (exit 1) and other expected non-zero returns to abort the sourcing shell.
# All errors are handled explicitly via conditional checks below.

# ---------------------------------------------------------------------------
# Skip-pattern classifier
# ---------------------------------------------------------------------------

# validate_body_classify_skip <subject>
# Returns 0 (match) if the subject starts with a well-known auto-generated
# prefix that should bypass body validation entirely, or if the subject
# contains the standard git cherry-pick trailer phrase.
validate_body_classify_skip() {
  local subject="$1"
  if [[ "$subject" =~ ^(Merge\ |Revert\ |fixup\!|squash\!|amend\!) ]]; then
    return 0
  fi
  # Cherry-pick commits: git appends "(cherry picked from commit <sha>)" to
  # the subject when using `git cherry-pick -x`. Match that standard phrase.
  if [[ "$subject" == *"(cherry picked from commit "* ]]; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# _vb_sha1 <text>
# Emit the SHA-1 hex digest of the given text (normalised: trimmed,
# whitespace collapsed). Falls back gracefully if sha1sum is absent.
_vb_sha1() {
  local text="$1"
  local normalised
  normalised=$(printf '%s' "$text" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
  if command -v sha1sum >/dev/null 2>&1; then
    printf '%s' "$normalised" | sha1sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$normalised" | shasum -a 1 | awk '{print $1}'
  else
    # Cannot compute SHA1; return empty so the duplicate-why check is skipped.
    printf ''
  fi
}

# _vb_log_skip <label> <reason>
# Append a skip-log entry to ~/.claude/var/gitgit-skips.log.
_vb_log_skip() {
  local label="$1"
  local reason="$2"
  local log_dir="$HOME/.claude/var"
  local log_file="$log_dir/gitgit-skips.log"
  # Create dir if it does not exist.  The Write-tool note says never use
  # mkdir; this is runtime bash, not a repo file, so mkdir -p is fine here.
  mkdir -p "$log_dir"
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')
  printf '%s|%s|%s\n' "$label" "$branch" "$reason" >> "$log_file"
}

# _vb_trailers <commit-msg-content>
# Parse trailers using git interpret-trailers --parse.
# Returns "Key: Value" lines on stdout.
_vb_trailers() {
  local content="$1"
  # git interpret-trailers requires a file or stdin.
  git interpret-trailers --parse <<< "$content" 2>/dev/null || true
}

# _vb_trailer_value <trailers-text> <key>
# Extract the value of the first matching trailer (case-insensitive key match).
_vb_trailer_value() {
  local trailers="$1"
  local key="$2"
  grep -i "^${key}:[[:space:]]*" <<< "$trailers" | head -1 | sed "s/^[^:]*:[[:space:]]*//" || true
}

# _vb_why_block <commit-msg-content> <trailers-text>
# Extract the WHY block: everything between the subject+blank-line and the
# start of the trailer block (or end of message if no trailers).
_vb_why_block() {
  local content="$1"
  local trailers="$2"

  # Strip subject line and the following blank line.
  local body
  body=$(printf '%s' "$content" | tail -n +3)

  if [[ -z "$trailers" ]]; then
    printf '%s' "$body"
    return 0
  fi

  # Find the first trailer line in the body and cut before it.
  # Build a pattern from the first trailer key.
  local first_trailer_line
  first_trailer_line=$(printf '%s' "$trailers" | head -1)
  local first_key
  first_key=$(printf '%s' "$first_trailer_line" | sed 's/:.*//')

  # Remove the trailer block from the body.
  local why
  why=$(printf '%s' "$body" | awk -v key="$first_key" '
    BEGIN { found=0 }
    tolower($0) ~ tolower("^" key ":") { found=1 }
    !found { print }
  ')
  # Strip trailing blank lines.
  why=$(printf '%s' "$why" | sed '/^[[:space:]]*$/{ H; d }; /[^[:space:]]/{ P; D }' 2>/dev/null \
        || printf '%s' "$why")
  printf '%s' "$why"
}

# UI-touch heuristic lives in its own lib so example-synth.sh and
# prepare-commit-msg can source the helper without dragging in the full
# validator. Provides _vb_ui_touched_files and _vb_is_ui_touch.
_VB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
# shellcheck disable=SC1091
. "$_VB_LIB_DIR/ui-touch.sh"

# ---------------------------------------------------------------------------
# Main validator
# ---------------------------------------------------------------------------

# validate_body <commit-msg-file-path>
validate_body() {
  local msg_file="$1"

  # exit 2: file unreadable or empty.
  if [[ ! -f "$msg_file" ]] || [[ ! -r "$msg_file" ]]; then
    printf 'unreadable-file: commit message file not found or not readable\n' >&2
    return 2
  fi

  local content
  content=$(cat "$msg_file")

  # Strip comment lines (lines starting with #) that git inserts.
  content=$(printf '%s' "$content" | grep -v '^#' || true)

  if [[ -z "$content" ]]; then
    printf 'empty-message: commit message is empty\n' >&2
    return 2
  fi

  # Rule: magic-comment opt-out via "# vsd-skip: <reason>".
  # (Must check the raw file including comment lines for this one.)
  local raw_content
  raw_content=$(cat "$msg_file")
  # Portable POSIX grep (no -P): extract reason after "# vsd-skip:".
  local skip_line
  skip_line=$(printf '%s' "$raw_content" | grep -E '^#[[:space:]]*vsd-skip:' | head -1 || true)
  if [[ -n "$skip_line" ]]; then
    local skip_reason
    skip_reason=$(printf '%s' "$skip_line" | sed -E 's/^#[[:space:]]*vsd-skip:[[:space:]]*//')
    if [[ -z "$skip_reason" ]]; then
      printf 'invalid-skip: vsd-skip requires a non-empty reason\n' >&2
      return 1
    fi
    # Autonomous mode forbids vsd-skip entirely. Rovers commit unattended
    # and the magic comment was the structural escape used to defer visual
    # evidence to a later phase that rarely materialised; closing it forces
    # the rover to either capture the screenshot now or articulate a real
    # Visual: n/a rationale that is not a deferral.
    if [[ "${GITGIT_AUTONOMOUS:-0}" = "1" ]]; then
      printf 'vsd-skip-autonomous: vsd-skip is disabled under GITGIT_AUTONOMOUS=1. Supply Visual: <path> with the screenshot, or Visual: n/a (rationale) if no UI was touched.\n' >&2
      return 1
    fi
    # vsd-skip cannot bypass commits that touch UI files. The opt-out was
    # designed for backend/spec/migration commits where the UI-touch
    # heuristic does not fire; using it on a UI commit defeats the entire
    # Visual gate. Operators must use Visual: <path> or Visual: n/a
    # (rationale) instead.
    if _vb_is_ui_touch; then
      local ui_files
      ui_files=$(_vb_ui_touched_files | tr '\n' ',' | sed 's/,$//;s/,/, /g')
      printf 'vsd-skip-ui-touch: vsd-skip cannot bypass commits that touch UI files: %s. Use Visual: <path> or Visual: n/a (rationale).\n' "$ui_files" >&2
      return 1
    fi
    local sha_label
    sha_label=$(git rev-parse --short HEAD 2>/dev/null || printf 'staging')
    _vb_log_skip "$sha_label" "$skip_reason"
    return 0
  fi

  # Parse subject (first non-empty line).
  local subject
  subject=$(printf '%s' "$content" | head -1)

  # exit 2: looks like a template or empty subject.
  if [[ -z "$subject" ]]; then
    printf 'empty-subject: first line of commit message is empty\n' >&2
    return 2
  fi

  # Rule: skip-pattern check (subject-level).
  if validate_body_classify_skip "$subject"; then
    return 0
  fi

  # Rule: cherry-pick detection in body. git cherry-pick -x appends the
  # "(cherry picked from commit <sha>)" line to the body, not just the subject.
  # When the body contains this phrase on its own line, skip validation.
  if printf '%s' "$content" | grep -qF '(cherry picked from commit '; then
    return 0
  fi

  # Determine if this is a single-line commit (no body lines after subject).
  local body_lines
  body_lines=$(printf '%s' "$content" | tail -n +2 | grep -v '^[[:space:]]*$' || true)
  local is_single_line=0
  if [[ -z "$body_lines" ]]; then
    is_single_line=1
  fi

  # Rule: single-line commit requires either GITGIT_TRIVIAL_OK=1 or a body.
  if [[ "$is_single_line" -eq 1 ]]; then
    if [[ "${GITGIT_TRIVIAL_OK:-0}" = "1" ]]; then
      return 0
    fi
    printf 'missing-body: subject-only commits require body or trivial flag from caller\n' >&2
    return 1
  fi

  # Parse trailers.
  local trailers
  trailers=$(_vb_trailers "$content")

  # Extract WHY block.
  local why_block
  why_block=$(_vb_why_block "$content" "$trailers")

  # Extract trailer values.
  local slice_value
  slice_value=$(_vb_trailer_value "$trailers" "Slice")

  local tests_value
  tests_value=$(_vb_trailer_value "$trailers" "Tests")

  local rtg_value
  rtg_value=$(_vb_trailer_value "$trailers" "Red-then-green")

  # Opt-out enum tokens. spec-only added: commits touching only spec/test
  # files don't need a Tests trailer (the diff is itself the test evidence).
  local OPT_OUT_ENUM="docs-only config-only migration-only spec-only chore-deps revert merge wip"

  # RTG-exempt tokens (subset of opt-out that also exempts Red-then-green).
  # migration-only and spec-only are exempt: a migration has no meaningful
  # red-then-green sequence; a spec-only commit is the red (the spec was
  # written first and drives the implementation in the next commit).
  local RTG_EXEMPT="docs-only config-only migration-only spec-only chore-deps"

  # Rule: Slice trailer must be present and non-empty.
  if [[ -z "$slice_value" ]]; then
    printf 'missing-slice: Slice trailer is absent or empty\n' >&2
    return 1
  fi

  # Determine if Slice value is an opt-out token.
  local slice_is_optout=0
  local token
  for token in $OPT_OUT_ENUM; do
    if [[ "$slice_value" = "$token" ]]; then
      slice_is_optout=1
      break
    fi
  done

  # Rule: free-text Slice must be at least 10 chars to carry meaningful context.
  if [[ "$slice_is_optout" -eq 0 ]] && [[ ${#slice_value} -lt 10 ]]; then
    printf 'slice-too-short: free-text Slice must be at least 10 chars (got: "%s")\n' "$slice_value" >&2
    return 1
  fi

  # Determine if Slice value is RTG-exempt.
  local slice_is_rtg_exempt=0
  for token in $RTG_EXEMPT; do
    if [[ "$slice_value" = "$token" ]]; then
      slice_is_rtg_exempt=1
      break
    fi
  done

  # Rule: if Slice is NOT an opt-out token, Tests trailer required.
  if [[ "$slice_is_optout" -eq 0 ]]; then
    if [[ -z "$tests_value" ]]; then
      printf 'missing-tests: Tests trailer is absent; required when Slice is not an opt-out token\n' >&2
      return 1
    fi

    # Rule: at least one Tests path must exist in HEAD tree or staged diff.
    local tests_ok=0
    local path

    # Collect paths from Tests value (comma- or newline-separated).
    local tests_paths
    tests_paths=$(printf '%s' "$tests_value" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep -v '^$' || true)

    # Build HEAD tree listing (best-effort; may fail on initial commit).
    local head_tree=""
    head_tree=$(git ls-tree -r HEAD --name-only 2>/dev/null || true)

    # Build staged diff listing.
    local staged_files=""
    staged_files=$(git diff --cached --name-only 2>/dev/null || true)

    while IFS= read -r path; do
      # Strip anchor suffixes like #method_name.
      local clean_path="${path%%#*}"
      clean_path="${clean_path%%,*}"
      clean_path=$(printf '%s' "$clean_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [[ -z "$clean_path" ]] && continue

      if grep -qF "$clean_path" <<< "$head_tree" 2>/dev/null \
         || grep -qF "$clean_path" <<< "$staged_files" 2>/dev/null; then
        tests_ok=1
        break
      fi
    done <<< "$tests_paths"

    # Validate path format for at least one entry.
    local path_re='[a-zA-Z0-9_./ -]+\.(rb|py|js|ts|go|sh|bash|bats|feature|tsx|jsx|swift)$'
    local has_valid_format=0
    while IFS= read -r path; do
      local clean_path="${path%%#*}"
      clean_path=$(printf '%s' "$clean_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [[ -z "$clean_path" ]] && continue
      if [[ "$clean_path" =~ $path_re ]]; then
        has_valid_format=1
        break
      fi
    done <<< "$tests_paths"

    if [[ "$has_valid_format" -eq 0 ]]; then
      printf 'missing-tests: Tests trailer contains no valid path (expected e.g. spec/foo_spec.rb)\n' >&2
      return 1
    fi

    if [[ "$tests_ok" -eq 0 ]]; then
      printf 'tests-path-not-found: no Tests path exists in HEAD tree or staged diff\n' >&2
      return 1
    fi
  fi

  # Rule: Red-then-green required unless Slice is RTG-exempt.
  if [[ "$slice_is_rtg_exempt" -eq 0 ]]; then
    if [[ -z "$rtg_value" ]]; then
      printf 'missing-red-then-green: Red-then-green trailer is absent; required for this Slice type\n' >&2
      return 1
    fi

    # Value must be "yes", "n/a", or "n/a (...)" with >=10 chars rationale.
    if [[ "$rtg_value" = "yes" ]]; then
      : # Self-attestation: "yes" is accepted as-is; no cache evidence required.
    elif [[ "$rtg_value" =~ ^n/a[[:space:]]*\((.+)\)$ ]]; then
      local rationale="${BASH_REMATCH[1]}"
      if [[ ${#rationale} -lt 10 ]]; then
        printf 'missing-red-then-green: n/a rationale must be at least 10 chars (got: "%s")\n' "$rationale" >&2
        return 1
      fi
    elif [[ "$rtg_value" = "n/a" ]]; then
      printf 'missing-red-then-green: bare "n/a" requires a rationale in parens: n/a (reason >= 10 chars)\n' >&2
      return 1
    else
      printf 'missing-red-then-green: value must be "yes" or "n/a (reason)"; got: "%s"\n' "$rtg_value" >&2
      return 1
    fi
  fi

  # Rule: Visual trailer.
  # Format is validated whenever the trailer is present, regardless of the
  # UI-touch heuristic; a malformed value is always a bug. The UI-touch
  # heuristic only decides whether ABSENCE of the trailer is a bug. Slice
  # tokens are not consulted: the trailer fires correctly on rare cases like
  # a chore-deps slice that also bumped a CSS dependency, and the format
  # check stays honest when an operator opts in on a backend-only commit.
  local visual_value
  visual_value=$(_vb_trailer_value "$trailers" "Visual")
  # git interpret-trailers normalises but a defensive trailing-whitespace
  # strip keeps the path-existence check honest if a trailer ever arrives
  # with trailing spaces.
  visual_value=$(printf '%s' "$visual_value" | sed 's/[[:space:]]*$//')

  # Compute the touched-files list once so the missing-visual error can name
  # them. _vb_ui_touched_files runs `git diff --cached --name-only` exactly
  # once per validator pass; reuse the output for both the absence check and
  # the error message.
  local visual_ui_touched
  visual_ui_touched=$(_vb_ui_touched_files)

  if [[ -n "$visual_value" ]]; then
    if [[ "$visual_value" =~ ^n/a[[:space:]]*\((.+)\)$ ]]; then
      local rationale="${BASH_REMATCH[1]}"
      if [[ ${#rationale} -lt 10 ]]; then
        printf 'missing-visual: n/a rationale must be at least 10 chars (got: "%s")\n' "$rationale" >&2
        return 1
      fi
      # Autonomous mode forbids n/a on UI-touched commits. A rover that
      # touched a SwiftUI view, .tsx component, or stylesheet can capture
      # a screenshot now; the n/a rationale was structurally a deferral
      # ("evidence lands in INSPECT") and that promise rarely paid off.
      if [[ "${GITGIT_AUTONOMOUS:-0}" = "1" ]] && [[ -n "$visual_ui_touched" ]]; then
        local autonomous_files
        autonomous_files=$(printf '%s' "$visual_ui_touched" | tr '\n' ',' | sed 's/,$//;s/,/, /g')
        printf 'visual-na-autonomous: Visual: n/a is not accepted under GITGIT_AUTONOMOUS=1 when UI files are touched (%s). Capture a screenshot and supply Visual: <path>.\n' "$autonomous_files" >&2
        return 1
      fi
    elif [[ "$visual_value" = "n/a" ]]; then
      printf 'missing-visual: bare "n/a" requires a rationale in parens: n/a (reason >= 10 chars)\n' >&2
      return 1
    else
      # Resolve relative to repo root so the check is stable whether the
      # caller is the git-native commit-msg hook (always repo root) or the
      # PreToolUse:Bash dispatcher (whatever subdirectory Claude invoked
      # from). Absolute paths in the trailer pass through unchanged.
      local repo_root
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
      local resolved="$visual_value"
      if [[ -n "$repo_root" && "$resolved" != /* ]]; then
        resolved="$repo_root/$resolved"
      fi
      if [[ ! -f "$resolved" ]]; then
        printf 'visual-path-not-found: Visual path "%s" was not found on disk (relative to repo root). Add the file or use Visual: n/a (rationale).\n' "$visual_value" >&2
        return 1
      fi
    fi
  elif [[ -n "$visual_ui_touched" ]]; then
    # Join the newline-separated list with ", " for the single-line error.
    local joined
    joined=$(printf '%s' "$visual_ui_touched" | tr '\n' ',' | sed 's/,$//;s/,/, /g')
    printf 'missing-visual: Visual trailer is absent; UI files in this commit: %s\n' "$joined" >&2
    return 1
  fi

  # Rule: WHY block length.
  # Require >= 2 non-empty lines OR (>= 60 chars AND ends with . ! or ?).
  if [[ -n "$why_block" ]]; then
    local nonempty_line_count
    nonempty_line_count=$(printf '%s' "$why_block" | grep -c '[^[:space:]]' || true)
    local why_charcount=${#why_block}
    local why_trimmed
    why_trimmed=$(printf '%s' "$why_block" | sed 's/[[:space:]]*$//')
    local last_char="${why_trimmed: -1}"

    local why_ok=0
    if [[ "$nonempty_line_count" -ge 2 ]]; then
      why_ok=1
    elif [[ "$why_charcount" -ge 60 ]] && [[ "$last_char" = "." || "$last_char" = "!" || "$last_char" = "?" ]]; then
      why_ok=1
    fi

    if [[ "$why_ok" -eq 0 ]]; then
      printf 'why-too-short: WHY block needs >= 2 non-empty lines or >= 60 chars ending in . ! or ?\n' >&2
      return 1
    fi
  else
    # No WHY block at all for a multi-line commit counts as too short.
    printf 'why-too-short: commit has a trailer block but no WHY narrative above it\n' >&2
    return 1
  fi

  # Rule: Anti-copy-paste. Compare SHA1 of WHY block against previous 5 commits.
  #
  # Scope note: the comparison is HEAD-linear (last 5 first-parent commits in
  # git log order), not strictly branch-scoped. A commit on a feature branch
  # will be compared against commits from main that HEAD is descended from if
  # those are within the 5-commit window. This is a deliberate choice: it
  # catches copy-paste from recently-merged main commits without requiring the
  # branch's merge-base to be computed, which is costly and fragile on shallow
  # clones. Trade-off: a commit immediately after a merge of a large batch may
  # compare against main-branch commits that are topically unrelated. In
  # practice the risk is low because the WHY blocks of unrelated commits rarely
  # hash-collide after whitespace normalisation.
  local why_sha
  why_sha=$(_vb_sha1 "$why_block")

  if [[ -n "$why_sha" ]]; then
    local log_bodies
    log_bodies=$(git log -5 --pretty=format:'%B' HEAD 2>/dev/null || true)

    if [[ -n "$log_bodies" ]]; then
      # Split log output into individual commit bodies and check each.
      # git log -5 --pretty=format:'%B' concatenates bodies with newlines.
      # We use a sentinel approach: split on double-blank-lines as separators.
      local prev_sha=""
      local prev_hash=""
      # Process commit log per-commit using git log with separators.
      while IFS= read -r commit_hash; do
        local prev_body
        prev_body=$(git log -1 --pretty=format:'%B' "$commit_hash" 2>/dev/null || true)
        local prev_trailers
        prev_trailers=$(_vb_trailers "$prev_body")
        local prev_why
        prev_why=$(_vb_why_block "$prev_body" "$prev_trailers")
        prev_sha=$(_vb_sha1 "$prev_why")
        if [[ -n "$prev_sha" ]] && [[ "$prev_sha" = "$why_sha" ]]; then
          local short_hash="${commit_hash:0:7}"
          printf 'duplicate-why: identical narrative as commit %s\n' "$short_hash" >&2
          return 1
        fi
      done < <(git log -5 --pretty=format:'%H' HEAD 2>/dev/null || true)
    fi
  fi

  return 0
}
