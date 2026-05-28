#!/bin/bash
# allow-comment: First-contact briefing guard. Mirrors commit-subject.sh wiring.

_DD_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

guard_git_first_contact() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [ -z "$command" ] && return 0

  local git_write_re='(^|[^A-Za-z0-9_/.-])git[[:space:]]+(commit|add|push|rebase|branch|switch|tag|cherry-pick|reset|restore)([[:space:]]|$)'
  [[ "$command" =~ $git_write_re ]] || return 0

  local sid
  sid=$(dd_session_id "$input")
  [ -z "$sid" ] && return 0

  local sentinel="/tmp/.claude-gitgit-briefed-${sid}"
  [ -f "$sentinel" ] && return 0
  touch "$sentinel" 2>/dev/null || return 0

  local skill_dir skill_path
  skill_dir=$(cd "$_DD_HERE/../../skills/commit-discipline" 2>/dev/null && pwd)
  skill_path="${skill_dir}/SKILL.md"
  if [ -f "$skill_path" ]; then
    [[ -n "$HOME" && "$skill_path" == "$HOME"/* ]] && skill_path="~${skill_path#$HOME}"
  else
    skill_path="(skill path unresolved; reinstall gitgit@leclause)"
  fi

  local msg="First git write in this session. Required commit form: heredoc inside a double-quoted -m, trailers (Slice/Tests/Red-then-green/Verified, plus Visual when UI is touched) contiguous at the bottom of the heredoc, ack-rule comment trailing the closing )\". Every commit also fires one rotation-reminder deny; the deny carries the rule essence and the row to look up the password in. Full canonical shape, anti-patterns, opt-out tokens: ${skill_path} (section 'Quick reference for AI'). Cost: each -m \"...\" paragraph counts separately (don't put trailers in their own -m), -F path is denied, embedded newlines inside -m truncate the body, conjunctions in the subject are rejected."

  dd_emit_pre_context git-first-contact "$msg"
}
