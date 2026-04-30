#!/bin/bash
# packages/gitgit/hooks/guards/commit-body.sh
# PreToolUse:Bash guard (shadow-mode). Parses the commit message from every
# "git commit" bash command, runs validate_body against it, and on violation
# emits a PreToolUse additionalContext warning (never denies). Logs every
# violation to the shadow log so the operator can measure false-positive rate
# before slice 4 flips this guard to block-mode.
#
# Activation gate: only the leclause-skills repo (detected via remote.origin.url)
# triggers validation. All other repos pass through silently.
#
# Trivial-commit optimisation: a commit touching <= 1 file and <= 5 insertions
# sets GITGIT_TRIVIAL_OK=1 before calling validate_body so the validator skips
# the body requirement.

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

  # Repo activation gate: only shadow-warn on the leclause-skills repo.
  local origin_url
  origin_url=$(git config --get remote.origin.url 2>/dev/null || true)
  if [[ "$origin_url" != *"epologee/leclause-skills"* ]]; then
    return 0
  fi

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
  violation_output=$(validate_body "$tmpfile" 2>&1 >/dev/null)
  exit_code=$?

  rm -f "$tmpfile"

  # exit 0: valid; exit 2: skip (unreadable / template). Both are silent.
  if [[ "$exit_code" -ne 1 ]]; then
    return 0
  fi

  # exit 1: violation. Emit a PreToolUse warning (never blocks).
  local violation_line
  violation_line=$(printf '%s' "$violation_output" | head -1)

  dd_emit_pre_context "commit-body-shadow" \
    "${violation_line} Add a body that meets the schema before slice 4 lands."

  # Append one line to the shadow log.
  local logfile="${GITGIT_SHADOW_LOG:-$HOME/.claude/var/gitgit-shadow.log}"
  mkdir -p "$(dirname "$logfile")"

  local timestamp branch short_sha violation_code subject_50
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')
  short_sha=$(git rev-parse --short HEAD 2>/dev/null || printf 'staging')
  violation_code=$(printf '%s' "$violation_line" | cut -d':' -f1)
  subject_50="${subject:0:50}"

  printf '%s|%s|%s|%s|%s\n' \
    "$timestamp" "$short_sha" "$branch" "$violation_code" "$subject_50" \
    >> "$logfile"

  # Guard always returns 0: warn only, never deny.
  return 0
}
