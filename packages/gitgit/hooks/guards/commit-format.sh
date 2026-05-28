#!/bin/bash
# allow-comment: PreToolUse:Bash guard. Walks the commit message line-by-line, collects format misses (72-char ceiling, missing blank line, conjunction in subject) and the soft 51-72 char nudge, then emits one dd_emit_pre_context. Hard misses ask for an amend afterwards; the soft nudge stays informational.

guard_commit_format() {
  local input="$1"
  local command message subject

  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  dd_is_git_commit_command "$command" || return 0

  message=$(dd_extract_commit_message "$command")
  [[ -z "$message" ]] && return 0

  subject=$(printf '%s' "$message" | head -1)

  local hard=() soft=()
  local line_num=0 subject_len=0 line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))

    if [[ ${#line} -gt 72 ]]; then
      if [[ $line_num -eq 1 ]]; then
        hard+=("Subject is ${#line} chars, max 72. Tighten: \"${line}\"")
      else
        hard+=("Body line ${line_num} is ${#line} chars, max 72: \"${line}\"")
      fi
    fi

    if [[ $line_num -eq 2 && -n "$line" ]]; then
      hard+=("Multi-line commit needs a blank line between subject and body.")
    fi

    if [[ $line_num -eq 1 ]]; then
      local conjunction_re=' (and|\+|&) '
      if [[ "$line" =~ $conjunction_re ]]; then
        local matched="${BASH_REMATCH[1]}"
        if [[ "${GITGIT_ALLOW_CONJUNCTION:-0}" != "1" ]] \
            && ! grep -qE '^# allow-conjunction:[[:space:]]+\S' <<< "$message"; then
          hard+=("Subject contains conjunction \" ${matched} \". Suggests two changes bundled behind one subject. Split into separate commits, rewrite as one cohesive change, or set GITGIT_ALLOW_CONJUNCTION=1 (or add '# allow-conjunction: <reason>' to the body) when the joined form is intentional.")
        fi
      fi
    fi

    [[ $line_num -eq 1 ]] && subject_len=${#line}
  done <<< "$message"

  if [[ $subject_len -gt 50 && $subject_len -le 72 ]]; then
    soft+=("Subject is ${subject_len} chars. Target is <=50; 51-72 is allowed but aim shorter on the next commit.")
  fi

  [[ ${#hard[@]} -eq 0 && ${#soft[@]} -eq 0 ]] && return 0

  local lines=()
  if [[ ${#hard[@]} -gt 0 ]]; then
    lines+=("Format issues; amend afterwards with git commit --amend:")
    local v
    for v in "${hard[@]}"; do
      lines+=("- ${v}")
    done
  fi
  if [[ ${#soft[@]} -gt 0 ]]; then
    [[ ${#lines[@]} -gt 0 ]] && lines+=("")
    local s
    for s in "${soft[@]}"; do
      lines+=("Note: ${s}")
    done
  fi

  local body_text
  body_text=$(printf '%s\n' "${lines[@]}")
  dd_emit_pre_context "commit-format" "$body_text"
}
