#!/bin/bash
# Shared library for the gitgit dispatcher and its guard functions.
# Sourced by dispatch.sh and guards/*.sh; never executed directly.
#
# Public helpers:
#   dd_event               - hook event from input JSON
#   dd_tool_name           - tool name from input JSON
#   dd_stop_active         - 0/1 based on stop_hook_active
#   dd_session_id          - session id from input JSON
#   dd_transcript          - transcript path, resolving session fallback
#   dd_assistant_text      - last-turn assistant text, optional line-tracking
#   dd_is_wip              - 0 if the assistant text contains 🚧
#   dd_emit_block          - Stop-style block JSON with mnemonic prefix
#   dd_emit_deny           - PreToolUse stderr + exit 2, mnemonic prefix
#   dd_emit_context        - PostToolUse additionalContext JSON, mnemonic prefix
#   dd_emit_pre_context    - PreToolUse additionalContext JSON, mnemonic prefix
#   dd_extract_commit_message - extract commit message from a bash command string
#
# Every emit helper prefixes the message with "[gitgit/<mnemonic>] ".
# That prefix is the stable code the operator and Claude can recognise at a
# glance without reading the whole reason.

dd_event() {
  jq -r '.hook_event_name // empty' <<< "$1" 2>/dev/null
}

dd_tool_name() {
  jq -r '.tool_name // empty' <<< "$1" 2>/dev/null
}

dd_stop_active() {
  local v
  v=$(jq -r '.stop_hook_active // false' <<< "$1" 2>/dev/null)
  [ "$v" = "true" ]
}

dd_session_id() {
  jq -r '.session_id // .sessionId // empty' <<< "$1" 2>/dev/null
}

dd_transcript() {
  local input="$1"
  local t
  t=$(jq -r '.transcript_path // empty' <<< "$input" 2>/dev/null)
  if [ -n "$t" ] && [ -f "$t" ]; then
    echo "$t"
    return 0
  fi
  local sid
  sid=$(dd_session_id "$input")
  [ -z "$sid" ] && return 1
  find ~/.claude/projects/ -name "${sid}.jsonl" -type f 2>/dev/null | head -1
}

dd_is_wip() {
  grep -q '🚧' <<< "$1"
}

# dd_assistant_text <input-json> <char-budget> [guard-name]
# Returns the tail of the current turn's assistant text.
# When guard-name is set, tracks last-seen transcript line count in
# /tmp/.claude-<guard>-<session>, scanning only new lines. This matches
# the pre-refactor behavior of the individual scripts.
dd_assistant_text() {
  local input="$1"
  local chars="${2:-1000}"
  local guard="${3:-}"

  local msg
  msg=$(jq -r '.last_assistant_message // empty' <<< "$input" 2>/dev/null)
  if [ -n "$msg" ]; then
    echo "$msg" | tail -c "$chars"
    return 0
  fi

  local sid
  sid=$(dd_session_id "$input")
  [ -z "$sid" ] && return 1

  local tr
  tr=$(dd_transcript "$input")
  [ -z "$tr" ] || [ ! -f "$tr" ] && return 1

  local tail_lines=50
  if [ -n "$guard" ]; then
    local line_file="/tmp/.claude-${guard}-${sid}"
    local total last
    total=$(wc -l < "$tr" | tr -d ' ')
    if [ -f "$line_file" ]; then
      last=$(cat "$line_file")
    else
      last=$((total > 30 ? total - 30 : 0))
    fi
    echo "$total" > "$line_file"
    tail_lines=$((total - last))
    [ "$tail_lines" -le 0 ] && return 1
  fi

  tail -"$tail_lines" "$tr" \
    | jq -s -r '
        . as $all
        | ([$all | to_entries[] | select(.value.type == "user") | .key] | last // -1) as $lu
        | $all[$lu + 1:]
        | map(select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text)
        | join("\n")
      ' 2>/dev/null \
    | tail -c "$chars"
}

# dd_emit_block <mnemonic> <message>
# Stop hook: print one-line JSON and exit 0. The reason carries the mnemonic
# prefix so the transcript shows e.g. [gitgit/cache] Cache is ...
dd_emit_block() {
  local mnemonic="$1"
  local msg="$2"
  jq -cn --arg r "[gitgit/${mnemonic}] ${msg}" '{decision:"block", reason:$r}'
  exit 0
}

# dd_emit_deny <mnemonic> <message>
# PreToolUse hook: print one-line stderr and exit 2 (blocks the tool).
dd_emit_deny() {
  local mnemonic="$1"
  local msg="$2"
  printf '[gitgit/%s] %s\n' "$mnemonic" "$msg" >&2
  exit 2
}

# dd_emit_context <mnemonic> <message>
# PostToolUse hook: print additionalContext JSON (does not block, surfaces text).
dd_emit_context() {
  local mnemonic="$1"
  local msg="$2"
  jq -cn --arg c "[gitgit/${mnemonic}] ${msg}" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
}

# dd_emit_pre_context <mnemonic> <message>
# PreToolUse hook: print additionalContext JSON (does not block, surfaces text
# to Claude in the next turn so it can adjust subsequent calls).
dd_emit_pre_context() {
  local mnemonic="$1"
  local msg="$2"
  jq -cn --arg c "[gitgit/${mnemonic}] ${msg}" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
}

# dd_extract_commit_message <bash-command>
# Extract the commit message from a bash command string.
# Tries heredoc body first (the pattern Claude Code defaults to for multi-line
# commits); falls back to all -m / -am / --message literals, joined with blank
# lines (matching git's paragraph-per-flag behavior).
# Prints the message on stdout, or nothing if no message is detected.
# Both commit-format.sh and commit-body.sh rely on this shared parser.
dd_extract_commit_message() {
  local command="$1"
  local message=""

  # Heredoc body extraction. Walks the command line-by-line, opens on
  # <<MARKER or <<-MARKER (quoted or unquoted), captures until a line whose
  # trimmed content matches the marker. Only the first heredoc is used.
  if [[ "$command" == *"<<"* ]]; then
    message=$(awk '
      in_hd {
        trimmed = $0
        sub(/^[[:space:]]+/, "", trimmed)
        if (trimmed == marker) { in_hd = 0; exit }
        print
        next
      }
      {
        if (match($0, /<<-?[[:space:]]*['"'"'"]?[A-Za-z_][A-Za-z0-9_]*['"'"'"]?/)) {
          tok = substr($0, RSTART, RLENGTH)
          sub(/<<-?[[:space:]]*['"'"'"]?/, "", tok)
          sub(/['"'"'"]?$/, "", tok)
          marker = tok
          in_hd = 1
        }
      }
    ' <<< "$command")
  fi

  # Fallback: all -m / -am / --message literals, joined with blank lines.
  # Multiple -m flags concatenate into subject + body paragraphs in git,
  # each separated by a blank line. Collect every match, strip the flag and
  # surrounding quotes from each, then join them with \n\n.
  if [[ -z "$message" ]]; then
    local all_dashm stripped para
    all_dashm=$(printf '%s' "$command" \
      | grep -oE -- $'(-[a-zA-Z]*m|--message)[[:space:]=]+("[^"]*"|\x27[^\x27]*\x27)' \
      || true)
    if [[ -n "$all_dashm" ]]; then
      stripped=""
      while IFS= read -r para; do
        local val
        val=$(printf '%s' "$para" \
          | sed -E $'s/^(-[a-zA-Z]*m|--message)[[:space:]=]+["\x27]//;s/["\x27]$//')
        if [[ -z "$stripped" ]]; then
          stripped="$val"
        else
          stripped="${stripped}"$'\n\n'"${val}"
        fi
      done <<< "$all_dashm"
      message="$stripped"
    fi
  fi

  printf '%s' "$message"
}
