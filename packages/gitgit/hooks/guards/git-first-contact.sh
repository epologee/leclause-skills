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
  [ -f "$skill_path" ] || skill_path="(skill path unresolved; reinstall gitgit@leclause)"

  local msg="First git write in this session. Before you commit, read the AI quick reference at ${skill_path} (section 'Quick reference for AI'). It carries the canonical commit shape that survives both the PreToolUse extractor and git interpret-trailers in one attempt: heredoc-inside-double-quote-m-flag, trailers contiguous at the bottom, ack-rule comment trailing the closing )-quote. Anti-patterns that cost attempts: multiple -m flags for trailers (only the last paragraph counts), -F path (denied as editor-mode), embedded newlines inside -m quoted args (truncates body), conjunctions in the subject. A rotation reminder fires on first commit per slot; the second attempt carries the ack. These reminders cycle one rule into focus so the rule actually gets read against this commit, not as a puzzle to slip past with synonyms."

  dd_emit_pre_context git-first-contact "$msg"
}
