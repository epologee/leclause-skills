#!/bin/bash
# packages/gitgit/hooks/guards/commit-format.sh
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

  # Delegate message extraction to the shared parser in common.sh so there
  # is a single canonical implementation (heredoc-first, -m fallback).
  local message
  message=$(dd_extract_commit_message "$command")

  [[ -z "$message" ]] && return 0

  # Iterate. line_num is 1-indexed for human-readable error messages.
  local line_num=0
  local subject_len=0
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

    # Subject must not join two changes with a conjunction. " and ",
    # " + " (space-plus-space), and " & " all signal that the author
    # bundled multiple changes behind one subject. Split into separate
    # commits or rewrite as one cohesive change. Authors who genuinely
    # need a conjunction set GITGIT_ALLOW_CONJUNCTION=1 in the shell
    # for the single commit; the magic-comment escape lives in the
    # body via "# allow-conjunction: <reason>".
    if [[ $line_num -eq 1 ]]; then
      local conjunction_re=' (and|\+|&) '
      if [[ "$line" =~ $conjunction_re ]]; then
        local matched="${BASH_REMATCH[1]}"
        if [[ "${GITGIT_ALLOW_CONJUNCTION:-0}" != "1" ]] \
            && ! grep -qE '^# allow-conjunction:[[:space:]]+\S' <<< "$message"; then
          dd_emit_deny commit-format "Subject contains conjunction \" ${matched} \". Suggests two changes bundled behind one subject. Split into separate commits, rewrite as one cohesive change, or set GITGIT_ALLOW_CONJUNCTION=1 (or add '# allow-conjunction: <reason>' to the body) when the joined form is intentional."
        fi
      fi
    fi

    [[ $line_num -eq 1 ]] && subject_len=${#line}
  done <<< "$message"

  # Aspirational warning: 51-72 chars. Non-blocking additionalContext so
  # Claude sees the nudge without losing the commit, and trends shorter on
  # subsequent commits in the same session.
  if [[ $subject_len -gt 50 && $subject_len -le 72 ]]; then
    dd_emit_pre_context commit-format "Subject is ${subject_len} chars. Target is <=50; 51-72 is allowed but aim shorter on the next commit."
  fi
}
