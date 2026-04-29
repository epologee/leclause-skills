#!/bin/bash
# PreToolUse:Bash guard. Enforce hard format limits on every git commit
# message: 72-char ceiling on every line (subject and body), and a blank
# separator line between subject and body for multi-line commits. The
# 50-char subject target is aspirational; nothing fires in 51-72.
#
# Heredoc-first parsing: when the command contains a heredoc, its body is
# the message. Otherwise the first -m / --message literal is the message.
# That ordering matters because Claude Code defaults nudge multi-line
# commits into `git commit -m "$(cat <<'EOF' ... EOF)"`, which a naive
# -m parser would mistake for a single-line subject containing `$(cat...)`.

guard_commit_format() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

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
        if (match($0, /<<-?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*['\''"]?/)) {
          tok = substr($0, RSTART, RLENGTH)
          sub(/<<-?[[:space:]]*['\''"]?/, "", tok)
          sub(/['\''"]?$/, "", tok)
          marker = tok
          in_hd = 1
        }
      }
    ' <<< "$command")
  fi

  # Fallback: first -m / -am / --message literal.
  if [[ -z "$message" ]]; then
    local dashm
    dashm=$(echo "$command" | grep -oE -- $'(-[a-zA-Z]*m|--message)[[:space:]=]+("[^"]*"|\x27[^\x27]*\x27)' | head -1 || true)
    if [[ -n "$dashm" ]]; then
      message=$(echo "$dashm" | sed -E $'s/^(-[a-zA-Z]*m|--message)[[:space:]=]+["\x27]//;s/["\x27]$//')
    fi
  fi

  [[ -z "$message" ]] && return 0

  # Iterate. line_num is 1-indexed for human-readable error messages.
  local line_num=0
  local saw_body=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    # Hard ceiling on every line.
    if [[ ${#line} -gt 72 ]]; then
      if [[ $line_num -eq 1 ]]; then
        dd_emit_deny commit-format "Subject is ${#line} chars, max 72. Tighten: \"${line}\""
      else
        dd_emit_deny commit-format "Body line ${line_num} is ${#line} chars, max 72: \"${line}\""
      fi
    fi

    # Multi-line commit: line 2 must be blank.
    if [[ $line_num -eq 2 && -n "$line" ]]; then
      dd_emit_deny commit-format "Multi-line commit needs a blank line between subject and body."
    fi

    [[ $line_num -ge 2 ]] && saw_body=1
  done <<< "$message"
}
