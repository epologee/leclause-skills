#!/bin/bash
# Shared library for dont-do-that Stop hooks.
# Centralizes transcript reading, mutex checks, and escape hatches.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"
#
#   INPUT=$(cat)
#   is_stop_hook_active "$INPUT" && exit 0
#
#   ASSISTANT_TEXT=$(read_assistant_text "$INPUT" [chars] [guard-name])
#   [ -z "$ASSISTANT_TEXT" ] && exit 0
#
#   is_wip_mode "$ASSISTANT_TEXT" && exit 0

# Check if another Stop hook already blocked this turn.
# Returns 0 (true) if active, 1 (false) if not.
is_stop_hook_active() {
  local active
  active=$(echo "$1" | jq -r '.stop_hook_active // false' 2>/dev/null)
  [ "$active" = "true" ]
}

# WIP escape hatch: 🚧 in assistant text means "working on hook system,
# let me through." Reduces false positives during hook development.
is_wip_mode() {
  echo "$1" | grep -q '🚧'
}

# Read assistant text from Stop hook input.
# $1: raw JSON input from hook
# $2: bytes to return (default 1000)
# $3: guard name for LINE_FILE tracking (omit to skip tracking)
read_assistant_text() {
  local input="$1"
  local chars="${2:-1000}"
  local guard_name="${3:-}"

  local assistant_msg
  assistant_msg=$(echo "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)

  if [ -n "$assistant_msg" ]; then
    echo "$assistant_msg" | tail -c "$chars"
    return 0
  fi

  local session_id
  session_id=$(echo "$input" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
  [ -z "$session_id" ] && return 1

  local transcript
  transcript=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
    transcript=$(find ~/.claude/projects/ -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
  fi
  [ -z "$transcript" ] || [ ! -f "$transcript" ] && return 1

  local tail_lines
  if [ -n "$guard_name" ]; then
    local line_file="/tmp/.claude-${guard_name}-${session_id}"
    local total_lines
    total_lines=$(wc -l < "$transcript" | tr -d ' ')
    local last_checked=0
    if [ -f "$line_file" ]; then
      last_checked=$(cat "$line_file")
    else
      last_checked=$((total_lines > 30 ? total_lines - 30 : 0))
    fi
    echo "$total_lines" > "$line_file"
    tail_lines=$((total_lines - last_checked))
    [ "$tail_lines" -le 0 ] && return 1
  else
    tail_lines=50
  fi

  tail -"$tail_lines" "$transcript" \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
    | tail -c "$chars"
}
