#!/bin/bash
# packages/gitgit/hooks/guards/commit-subject.sh
# PreToolUse:Bash guard. On every git commit, parse the subject from -m /
# --message / HEREDOC; check rules 1 (activity-word start) and 2 (trigger
# phrasing); otherwise serve a rotating thematic reminder. Blocks until an
# appropriate '# ack-rule<N>:<wachtwoord>' token appears, where the
# wachtwoord must match the mnemonic for that rule. The mnemonics live in
# hooks/lib/rotation-rules.sh and are documented in the
# /gitgit:commit-discipline skill (section "Rotation reminders").
#
# State: three lines at $GITGIT_COMMIT_RULE_STATE_FILE (fallback
# $HOME/.claude/var/gitgit-commit-rule-state): pending_violation,
# pending_rotation, rotation_pos. Written atomically via temp-file rename.
#
# One-shot migration: if the old dont-do-that state file exists and the new
# one does not, the old file is copied to the new path on first run.

# Source the password mnemonics; provides DD_RULE_PASSWORD[].
_DD_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DD_HERE/../lib/rotation-rules.sh"

# Rule 3 (idx 2) is owned by commit-format structurally and stays out of
# the rotation so it does not double up as an ack-bypassable reminder.
_DD_ROTATION_SLOTS=(3 4 5 6 7 8 9 10 11 12 13)

_dd_read_state_line() {
  local file="$1" line_no="$2" default="$3"
  local v
  v=$(sed -n "${line_no}p" "$file" 2>/dev/null)
  if [[ "$v" =~ ^-?[0-9]+$ ]]; then
    echo "$v"
  else
    echo "$default"
  fi
}

_dd_write_state() {
  local file="$1" pv="$2" pr="$3" rp="$4" ack_sha="${5:-}"
  local tmp="${file}.tmp.$$"
  printf '%d\n%d\n%d\n%s\n' "$pv" "$pr" "$rp" "$ack_sha" > "$tmp"
  mv "$tmp" "$file"
}

# Returns 0 when the parsed ack matches the expected rule and password.
# All inputs are explicit so the caller can be reasoned about without
# tracing into the helper's enclosing scope.
_dd_ack_matches() {
  local target_idx="$1" ack_idx="$2" ack_password="$3" expected="$4"
  [[ "$ack_idx" -ne "$target_idx" ]] && return 1
  [[ -z "$ack_password" ]] && return 1
  [[ "$ack_password" != "$expected" ]] && return 1
  return 0
}

# Writes the new state and then exits the dispatcher with code 2 via
# dd_emit_deny. Never returns; any code following a call to this
# function in the same branch is unreachable.
_dd_deny_and_exit() {
  local rule_idx="$1" msg="$2" pv="$3" pr="$4" rp="$5" state_file="$6" ack_sha="${7:-}"
  local num=$((rule_idx + 1))
  _dd_write_state "$state_file" "$pv" "$pr" "$rp" "$ack_sha"
  dd_emit_deny commit-subject "Rule ${num}/14: ${msg}"
}

guard_commit_subject() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

  # Direct pointer to the SKILL.md so Claude can Read the file without
  # grep-fishing through the plugin cache. The lookup itself stays
  # required: this only points at the door, the password still lives
  # behind it. Falls back to the slash-command form when the absolute
  # path cannot be resolved (e.g. broken install).
  local skill_pointer
  if skill_pointer=$(cd "$_DD_HERE/../../skills/commit-discipline" 2>/dev/null && pwd); then
    skill_pointer="${skill_pointer}/SKILL.md, section 'Rotation reminders'"
  else
    skill_pointer="/gitgit:commit-discipline"
  fi

  # Subject extraction: delegate to dd_extract_commit_message (shared parser),
  # then take the first line as the subject. This deduplicates the heredoc-first
  # / -m-fallback logic that commit-format.sh and commit-body.sh also use.
  local full_message
  full_message=$(dd_extract_commit_message "$command")
  local subject=""
  if [[ -n "$full_message" ]]; then
    subject=$(printf '%s' "$full_message" | head -1)
  fi

  # Strip HEREDOC body + quoted strings from command for ack-token detection,
  # so an ack buried in the subject itself does not count as approval.
  local cmd_clean
  cmd_clean=$(echo "$command" | awk '
    BEGIN { in_heredoc=0; marker="" }
    in_heredoc {
      trimmed = $0
      sub(/^[[:space:]]+/, "", trimmed)
      if (trimmed == marker) { in_heredoc = 0; marker = "" }
      next
    }
    {
      if (match($0, /<<-?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*['\''"]?/)) {
        tok = substr($0, RSTART, RLENGTH)
        sub(/<<-?[[:space:]]*['\''"]?/, "", tok)
        sub(/['\''"]?$/, "", tok)
        marker = tok
        in_heredoc = 1
      }
      print
    }' || true)
  cmd_clean=$(echo "$cmd_clean" | sed -E $'s/"[^"]*"//g; s/\x27[^\x27]*\x27//g' || true)

  # Optional :<password> suffix. Bare `# ack-rule<N>` is still recognised as
  # "user tried to ack" (drives the "overtreedt nog" branch when their subject
  # is still violating); only the suffixed form actually clears state.
  local ack_idx=-1
  local ack_password=""
  if [[ "$cmd_clean" =~ (^|[[:space:]])\#[[:space:]]*ack-rule([0-9]+)(:([a-z]+))? ]]; then
    ack_idx=$((${BASH_REMATCH[2]} - 1))
    ack_password="${BASH_REMATCH[4]}"
  fi

  # Rule 1 (idx 0) / Rule 2 (idx 1) violation detection on the subject.
  local activity_re='^(Fix|Improve|Update|Change|Refactor|Add|Extract|Move|Remove|Rename|Drop|Create|Clear)[[:space:]]'
  local trigger_re='^(Address|Apply)[[:space:]]+.*(review|feedback|findings|comments|pride)'
  local violation_idx=-1
  shopt -s nocasematch
  if [[ -n "$subject" ]] && [[ "$subject" =~ $trigger_re ]]; then
    violation_idx=1
  elif [[ -n "$subject" ]] && [[ "$subject" =~ $activity_re ]]; then
    violation_idx=0
  fi
  shopt -u nocasematch

  # State file. GITGIT_COMMIT_RULE_STATE_FILE overrides for tests.
  # One-shot migration from the old dont-do-that location.
  local state_file="${GITGIT_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/gitgit-commit-rule-state}"
  mkdir -p "$(dirname "$state_file")"
  if [[ ! -f "$state_file" ]]; then
    local old_state_file="${CLAUDE_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/commit-rule-state}"
    if [[ -f "$old_state_file" ]]; then
      cp "$old_state_file" "$state_file"
    fi
  fi

  local pv pr rp ack_pending_sha=""
  pv=-1; pr=-1; rp=0
  if [[ -f "$state_file" ]]; then
    pv=$(_dd_read_state_line "$state_file" 1 -1)
    pr=$(_dd_read_state_line "$state_file" 2 -1)
    rp=$(_dd_read_state_line "$state_file" 3 0)
    ack_pending_sha=$(sed -n '4p' "$state_file" 2>/dev/null | tr -cd '0-9a-f')
  fi
  # Clamp to valid ranges.
  [[ "$pv" -ne -1 && "$pv" -ne 0 && "$pv" -ne 1 ]] && pv=-1
  if [[ "$pr" -ne -1 ]]; then
    local in_rot=0 slot
    for slot in "${_DD_ROTATION_SLOTS[@]}"; do
      [[ "$slot" -eq "$pr" ]] && { in_rot=1; break; }
    done
    [[ "$in_rot" -eq 0 ]] && pr=-1
  fi
  [[ "$rp" -lt 0 || "$rp" -ge "${#_DD_ROTATION_SLOTS[@]}" ]] && rp=0

  # Resolve any pending ack from a previous PreToolUse pass: if HEAD has
  # advanced since the ack was matched, the commit actually landed and the
  # rotation slot is consumed. If HEAD is unchanged, the commit failed at
  # commit-msg, pre-commit, or never ran; the slot stays so the operator
  # acks the same rule again on the next attempt. Either way, clear the
  # pending sha so this resolution only runs once per ack.
  if [[ -n "$ack_pending_sha" ]]; then
    local current_sha
    current_sha=$(git rev-parse HEAD 2>/dev/null | tr -cd '0-9a-f')
    if [[ -n "$current_sha" && "$current_sha" != "$ack_pending_sha" ]]; then
      rp=$(( (rp + 1) % ${#_DD_ROTATION_SLOTS[@]} ))
    fi
    ack_pending_sha=""
    _dd_write_state "$state_file" "$pv" "$pr" "$rp" ""
  fi

  # Editor-mode commit: no subject parseable, rules 1/2 cannot be checked.
  if [[ -z "$subject" ]]; then
    dd_emit_deny commit-subject "Editor-mode commit verbergt subject. Pass inline: git commit -m \"...\"."
  fi

  # Fresh violation: always deny with rule 1 or 2.
  if [[ "$violation_idx" -ge 0 ]]; then
    local rn=$((violation_idx + 1))
    if [[ "$ack_idx" -eq "$violation_idx" ]]; then
      _dd_deny_and_exit "$violation_idx" \
        "\"${subject}\" overtreedt nog. Rewrite + '# ack-rule${rn}:<wachtwoord>' (lookup: ${skill_pointer})." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    else
      _dd_deny_and_exit "$violation_idx" \
        "\"${subject}\" overtreedt. Rewrite + '# ack-rule${rn}:<wachtwoord>' (lookup: ${skill_pointer})." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    fi
  fi

  # Pending violation from a previous call: subject must be clean AND ack
  # must carry the right password.
  if [[ "$pv" -ge 0 ]]; then
    if _dd_ack_matches "$pv" "$ack_idx" "$ack_password" "${DD_RULE_PASSWORD[$pv]}"; then
      _dd_write_state "$state_file" -1 "$pr" "$rp"
      return 0
    fi
    _dd_deny_and_exit "$pv" \
      "\"${subject}\" wachtwoord onjuist of ontbreekt. Plak '# ack-rule$((pv + 1)):<wachtwoord>' (lookup: ${skill_pointer})." \
      "$pv" "$pr" "$rp" "$state_file"
  fi

  # No pending rotation: serve the next slot as a rotating thematic reminder.
  if [[ "$pr" -lt 0 ]]; then
    local selected="${_DD_ROTATION_SLOTS[$rp]}"
    _dd_deny_and_exit "$selected" \
      "reminder. Plak '# ack-rule$((selected + 1)):<wachtwoord>' (lookup: ${skill_pointer})." \
      -1 "$selected" "$rp" "$state_file"
  fi

  # Pending rotation: ack must match exactly with the right password.
  # Rotation only advances on confirmed commit success, not on PreToolUse
  # pass: record the current HEAD sha so the next dispatcher entry can
  # detect whether the commit actually landed (HEAD moved) or failed at
  # commit-msg / pre-commit (HEAD unchanged).
  if _dd_ack_matches "$pr" "$ack_idx" "$ack_password" "${DD_RULE_PASSWORD[$pr]}"; then
    local head_sha
    head_sha=$(git rev-parse HEAD 2>/dev/null | tr -cd '0-9a-f')
    _dd_write_state "$state_file" -1 -1 "$rp" "$head_sha"
    return 0
  fi
  _dd_deny_and_exit "$pr" \
    "wachtwoord onjuist of ontbreekt. Plak '# ack-rule$((pr + 1)):<wachtwoord>' (lookup: ${skill_pointer})." \
    -1 "$pr" "$rp" "$state_file"
}
