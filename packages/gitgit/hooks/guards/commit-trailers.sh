#!/bin/bash
# packages/gitgit/hooks/guards/commit-trailers.sh
# PreToolUse:Bash guard. Blocks Co-Authored-By: trailers with @anthropic.com
# email in commit messages, unless explicitly opted in via env var. Absorbed
# from ~/.claude/hooks/block-coauthored-trailer.sh.
#
# Behaviour mirrors the original block-coauthored-trailer.sh: only anthropic.com
# trailers are blocked; human Co-Authored-By trailers (real teammates) pass.
# Widen the scope later if the operator asks. The user-level CLAUDE.md text
# rule "geen Co-Authored-By: trailer" is broader than this hook; the hook
# implements the historically-enforced subset.
#
# Bypass: set GITGIT_ALLOW_AI_COAUTHOR=1 in the environment for one bash call
# when an anthropic.com co-author trailer is genuinely desired.

guard_commit_trailers() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

  # Explicit opt-in skips the guard silently.
  [[ "${GITGIT_ALLOW_AI_COAUTHOR:-0}" = "1" ]] && return 0

  local message
  message=$(dd_extract_commit_message "$command")
  [[ -z "$message" ]] && return 0

  # Case-insensitive match on Co-Authored-By: + anthropic.com email anywhere
  # in the body. Covers both "noreply@anthropic.com" and any other
  # "...@anthropic.com" form a future template might generate.
  if grep -qiE '^[[:space:]]*Co-Authored-By:[[:space:]].*@anthropic\.com' <<< "$message"; then
    dd_emit_deny "commit-trailers" "Co-Authored-By: anthropic email is blocked. Add GITGIT_ALLOW_AI_COAUTHOR=1 to bypass when explicitly desired."
  fi
}
