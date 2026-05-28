#!/bin/bash
# allow-comment: PreToolUse:Bash guard. Validates the commit message against the body schema and emits dd_emit_pre_context (additionalContext, non-blocking) when the body falls short. Commit lands; Claude reads the nudge and amends. amend commits validate against HEAD (the to-be-rewritten state); normal commits validate against the staged area.

guard_commit_body() {
  local input="$1"

  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  dd_is_git_commit_command "$command" || return 0

  local message
  message=$(dd_extract_commit_message "$command")
  [[ -z "$message" ]] && return 0

  local subject
  subject=$(printf '%s' "$message" | head -1)
  if validate_body_classify_skip "$subject"; then
    return 0
  fi

  local validate_ctx="staged"
  if [[ "$command" == *--amend* ]]; then
    validate_ctx="HEAD"
  fi

  local shortstat file_count insertion_count
  shortstat=$(GITGIT_VALIDATE_CONTEXT="$validate_ctx" _vb_delta_shortstat)
  file_count=$(GITGIT_VALIDATE_CONTEXT="$validate_ctx" _vb_delta_files | grep -c . | tr -d ' ')

  insertion_count=0
  if [[ "$shortstat" =~ ([0-9]+)[[:space:]]+insertion ]]; then
    insertion_count="${BASH_REMATCH[1]}"
  fi

  if [[ "$file_count" -le 1 && "$insertion_count" -le 5 ]]; then
    export GITGIT_TRIVIAL_OK=1
  else
    export GITGIT_TRIVIAL_OK=0
  fi

  local tmpfile
  tmpfile=$(mktemp /tmp/gitgit-commit-msg-XXXXXX)
  printf '%s' "$message" > "$tmpfile"

  local violation_output exit_code
  violation_output=$(GITGIT_VALIDATE_CONTEXT="$validate_ctx" validate_body "$tmpfile" 2>&1)
  exit_code=$?

  rm -f "$tmpfile"

  if [[ "$exit_code" -ne 1 ]]; then
    return 0
  fi

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
  subject_50="${subject_50//|/-}"
  branch="${branch//|/-}"
  violation_code="${violation_code//|/-}"

  printf '%s|%s|%s|%s|%s\n' \
    "$timestamp" "$short_sha" "$branch" "$violation_code" "$subject_50" \
    >> "$logfile"

  local example
  example=$(GITGIT_VALIDATE_CONTEXT="$validate_ctx" gitgit_synthesize_example 2>/dev/null || printf '<example unavailable>')

  local opt_out_list="docs-only, config-only, migration-only, spec-only, chore-deps, revert, merge, wip"

  local nudge
  nudge=$(printf '%s\n\nThe commit will land regardless; amend afterwards with git commit --amend -F <new-message-file>. push-body-gate will block the push if the body is still non-conformant at push time.\n\nExpected body format:\n\n%s\n\nOpt-out tokens for Slice: %s' \
    "$violation_line" \
    "$example" \
    "$opt_out_list")

  dd_emit_pre_context "commit-body" "$nudge"
}
