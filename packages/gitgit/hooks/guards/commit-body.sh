#!/bin/bash
# packages/gitgit/hooks/guards/commit-body.sh
# PreToolUse:Bash guard (block-mode, slice 4). Parses the commit message from
# every "git commit" bash command, runs validate_body against it, and on
# violation emits dd_emit_deny (exit 2, blocks the tool call). Previously
# shadow-mode in slice 3; now universal across all repos.
#
# Shadow log: violations are still written to the shadow log as a parallel
# audit record regardless of repo. The repo-gate that limited slice 3 to the
# leclause-skills repo is removed; block-mode is universal.
#
# Trivial-commit optimisation: a commit touching <= 1 file and <= 5 insertions
# sets GITGIT_TRIVIAL_OK=1 before calling validate_body so the validator skips
# the body requirement. This threshold is unchanged from slice 3.
#
# Magic-comment opt-out: "# vsd-skip: <reason>" in the commit message body is
# honoured by validate_body.sh which logs to gitgit-skips.log.

guard_commit_body() {
  local input="$1"

  # Only act on git commit commands.
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

  # Extract the commit message. Empty means editor-mode; commit-format.sh
  # already handles editor-mode, so skip silently here.
  local message
  message=$(dd_extract_commit_message "$command")
  [[ -z "$message" ]] && return 0

  # Subject skip-pattern check (Merge / Revert / fixup! / squash! / amend!).
  local subject
  subject=$(printf '%s' "$message" | head -1)
  if validate_body_classify_skip "$subject"; then
    return 0
  fi

  # Trivial-commit detection: <= 1 file AND <= 5 insertions -> set TRIVIAL_OK.
  local shortstat file_count insertion_count
  shortstat=$(git diff --cached --shortstat 2>/dev/null || true)
  file_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  # Extract insertions from shortstat output ("N insertions(+)").
  insertion_count=0
  if [[ "$shortstat" =~ ([0-9]+)[[:space:]]+insertion ]]; then
    insertion_count="${BASH_REMATCH[1]}"
  fi

  if [[ "$file_count" -le 1 && "$insertion_count" -le 5 ]]; then
    export GITGIT_TRIVIAL_OK=1
  else
    export GITGIT_TRIVIAL_OK=0
  fi

  # Write message to a temp file and invoke the shared validator.
  local tmpfile
  tmpfile=$(mktemp /tmp/gitgit-commit-msg-XXXXXX)
  printf '%s' "$message" > "$tmpfile"

  local violation_output exit_code
  violation_output=$(validate_body "$tmpfile" 2>&1)
  exit_code=$?

  rm -f "$tmpfile"

  # exit 0: valid; exit 2: skip (unreadable / template). Both are silent.
  if [[ "$exit_code" -ne 1 ]]; then
    return 0
  fi

  # exit 1: violation. Always write to shadow log (all repos).
  local violation_line
  violation_line=$(printf '%s' "$violation_output" | head -1)
  local violation_code
  violation_code=$(printf '%s' "$violation_line" | cut -d':' -f1)

  local logfile="${GITGIT_SHADOW_LOG:-$HOME/.claude/var/gitgit-shadow.log}"
  mkdir -p "$(dirname "$logfile")"

  local timestamp branch short_sha subject_50
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')
  short_sha=$(git rev-parse --short HEAD 2>/dev/null || printf 'staging')
  subject_50="${subject:0:50}"
  # Sanitise pipe characters in all operator-controlled fields so the log
  # parser does not mistake them for field delimiters. Replacement: dash (-).
  subject_50="${subject_50//|/-}"
  branch="${branch//|/-}"
  violation_code="${violation_code//|/-}"

  printf '%s|%s|%s|%s|%s\n' \
    "$timestamp" "$short_sha" "$branch" "$violation_code" "$subject_50" \
    >> "$logfile"

  # Synthesize a filled example from the staged diff.
  local example
  example=$(gitgit_synthesize_example 2>/dev/null || printf '<example unavailable>')

  # Opt-out enum list.
  local opt_out_list="docs-only, config-only, migration-only, spec-only, chore-deps, revert, merge, wip"

  # Build the deny message.
  local deny_msg
  deny_msg=$(printf '%s\n\nExpected body format:\n\n%s\n\nOpt-out tokens for Slice: %s\n\nAdd "# vsd-skip: <reason>" to the commit body to bypass validation.' \
    "$violation_line" \
    "$example" \
    "$opt_out_list")

  dd_emit_deny "commit-body" "$deny_msg"
}
