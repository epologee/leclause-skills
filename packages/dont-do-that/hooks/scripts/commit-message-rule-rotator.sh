#!/bin/bash
set -euo pipefail
trap 'echo "commit-message-rule-rotator: internal error, denying commit to surface the bug. Inspect the hook script." >&2; exit 2' ERR

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ ! "$command" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

subject=""
dashm=$(echo "$command" | grep -oE -- $'(-[a-zA-Z]*m|--message)[[:space:]=]+("[^"]*"|\x27[^\x27]*\x27)' | head -1 || true)
if [[ -n "$dashm" ]]; then
  subject=$(echo "$dashm" | sed -E $'s/^(-[a-zA-Z]*m|--message)[[:space:]=]+["\x27]//;s/["\x27]$//')
fi
if [[ -z "$subject" ]]; then
  heredoc=$(echo "$command" | awk '/<<-?[[:space:]]*['\''"]?[A-Z]+['\''"]?/{flag=1; next} flag && NF {print; exit}' || true)
  if [[ -n "$heredoc" ]]; then
    subject="$heredoc"
  fi
fi

rules=(
  "Subject describes new behaviour or capability, not the git activity. Activity-word start (Fix, Improve, Update, Change, Refactor, Add, Extract, Move, Remove, Rename, Drop, Create, Clear) hides the result behind the operation."
  "Do not reference the trigger. Address review/feedback/findings, Apply PR comments, Fix review comments describe why you are writing a commit, not what the system does now."
  "Subject fits in 50 characters (target), 72 max. Imperative mood, English. Rewrite if the subject summarises what changed instead of naming the new behaviour."
  "Body only when needed: 2 to 4 sentences of prose explaining why the change was made."
  "No file listings, no class or module inventories. The diff already shows which files changed."
  "No bullet dumps. No meta narrative about how the commit came to exist (reviewer asked, tests failed, and so on)."
  "Logically independent changes are separate commits. Test and implementation of the same feature are one atomic commit. Formatting drifts do not belong in feature commits."
  "Never commit broken code with intent to fix it in the next commit. Atomic means small logical units of working code."
  "No Co-Authored-By trailers added by AI tooling unless the user asked for them."
  "No Generated with Claude Code footer or similar tool signature."
  "Review the staged diff before committing. The Edit tool saying updated successfully is not proof the change is complete."
  "The commit check is evidence, not gut feel. Ran the test, hit the endpoint, checked the state. Not the code looks correct."
  "Never squash merge. Preserve commit history so reviewers see the iteration."
  "Amend is banned except to strip unpushed secrets or PII. Use a new commit to make follow-up corrections."
)

rotation_reminder_slots=(2 3 4 5 6 7 8 9 10 11 12 13)

activity_regex='^(Fix|Improve|Update|Change|Refactor|Add|Extract|Move|Remove|Rename|Drop|Create|Clear)[[:space:]]'
trigger_regex='^(Address|Apply)[[:space:]]+.*(review|feedback|findings|comments|pride)'

violation_idx=-1
shopt -s nocasematch
if [[ -n "$subject" ]] && [[ "$subject" =~ $trigger_regex ]]; then
  violation_idx=1
elif [[ -n "$subject" ]] && [[ "$subject" =~ $activity_regex ]]; then
  violation_idx=0
fi
shopt -u nocasematch

command_no_heredoc=$(echo "$command" | awk '
  BEGIN { in_heredoc=0; marker="" }
  in_heredoc {
    trimmed = $0
    sub(/^[[:space:]]+/, "", trimmed)
    if (trimmed == marker) {
      in_heredoc = 0
      marker = ""
    }
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
  }
' || true)

command_stripped=$(echo "$command_no_heredoc" | sed -E $'s/"[^"]*"//g; s/\x27[^\x27]*\x27//g' || true)

ack_idx=-1
if [[ "$command_stripped" =~ (^|[[:space:]])\#[[:space:]]*ack-rule([0-9]+) ]]; then
  ack_num="${BASH_REMATCH[2]}"
  ack_idx=$((ack_num - 1))
fi

state_file="${CLAUDE_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/commit-rule-state}"
mkdir -p "$(dirname "$state_file")"

read_line() {
  local lineno="$1"
  local default="$2"
  local value
  value=$(sed -n "${lineno}p" "$state_file" 2>/dev/null || true)
  if [[ "$value" =~ ^-?[0-9]+$ ]]; then
    echo "$value"
  else
    echo "$default"
  fi
}

pending_violation_idx=-1
pending_rotation_idx=-1
rotation_pos=0
if [[ -f "$state_file" ]]; then
  pending_violation_idx=$(read_line 1 -1)
  pending_rotation_idx=$(read_line 2 -1)
  rotation_pos=$(read_line 3 0)
fi

if [[ "$pending_violation_idx" -ne -1 ]] && [[ "$pending_violation_idx" -ne 0 ]] && [[ "$pending_violation_idx" -ne 1 ]]; then
  pending_violation_idx=-1
fi

if [[ "$pending_rotation_idx" -ne -1 ]]; then
  in_rotation=0
  for slot in "${rotation_reminder_slots[@]}"; do
    if [[ "$slot" -eq "$pending_rotation_idx" ]]; then
      in_rotation=1
      break
    fi
  done
  if [[ "$in_rotation" -eq 0 ]]; then
    pending_rotation_idx=-1
  fi
fi

if [[ "$rotation_pos" -lt 0 ]] || [[ "$rotation_pos" -ge "${#rotation_reminder_slots[@]}" ]]; then
  rotation_pos=0
fi

write_state() {
  local pv="$1"
  local pr="$2"
  local rp="$3"
  local tmp="${state_file}.tmp.$$"
  printf '%d\n%d\n%d\n' "$pv" "$pr" "$rp" > "$tmp"
  mv "$tmp" "$state_file"
}

emit_deny() {
  local selected_idx="$1"
  local reason_line="$2"
  local action_line="$3"
  local pv="$4"
  local pr="$5"
  local rp="$6"
  local rule_num=$((selected_idx + 1))
  local rule_text="${rules[$selected_idx]}"
  {
    echo "=== commit rule block ==="
    if [[ -n "$subject" ]]; then
      echo "Subject: \"$subject\""
    fi
    echo "Rule [$rule_num/14]: $rule_text"
    echo ""
    echo "$reason_line"
    echo ""
    echo "$action_line"
    echo "==========================="
  } >&2
  write_state "$pv" "$pr" "$rp"
  exit 2
}

if [[ -z "$subject" ]]; then
  {
    echo "=== commit rule block ==="
    echo "Rule inspection skipped: no subject could be parsed from the command."
    echo ""
    echo "Editor-mode commits (no -m, no --message, no HEREDOC) hide the subject from this hook, so rules 1 and 2 (activity-word start, trigger-as-reason phrasing) cannot be checked."
    echo ""
    echo "Required: pass the subject inline, e.g. git commit -m \"Your subject\"."
    echo "==========================="
  } >&2
  exit 2
fi

if [[ "$violation_idx" -ge 0 ]]; then
  if [[ "$ack_idx" -eq "$violation_idx" ]]; then
    emit_deny "$violation_idx" \
      "The '#ack-rule$((violation_idx + 1))' is present, but the subject still violates this rule." \
      "Required: rewrite the subject so it no longer violates, keep the ack, then re-run." \
      "$violation_idx" "$pending_rotation_idx" "$rotation_pos"
  else
    emit_deny "$violation_idx" \
      "The subject violates this rule." \
      "Required: rewrite the subject so it no longer violates, then add '# ack-rule$((violation_idx + 1))' as a trailing bash comment." \
      "$violation_idx" "$pending_rotation_idx" "$rotation_pos"
  fi
fi

if [[ "$pending_violation_idx" -ge 0 ]]; then
  if [[ "$ack_idx" -eq "$pending_violation_idx" ]]; then
    write_state -1 "$pending_rotation_idx" "$rotation_pos"
    exit 0
  else
    emit_deny "$pending_violation_idx" \
      "The subject is clean now, but the '#ack-rule$((pending_violation_idx + 1))' bash comment is missing." \
      "Required: add '# ack-rule$((pending_violation_idx + 1))' as a trailing bash comment to confirm you read the rule." \
      "$pending_violation_idx" "$pending_rotation_idx" "$rotation_pos"
  fi
fi

if [[ "$pending_rotation_idx" -lt 0 ]]; then
  selected_idx="${rotation_reminder_slots[$rotation_pos]}"
  emit_deny "$selected_idx" \
    "Subject is clean. This is a rotating thematic reminder, not a violation." \
    "Required: add '# ack-rule$((selected_idx + 1))' as a trailing bash comment to confirm you read the rule, then re-run." \
    "-1" "$selected_idx" "$rotation_pos"
fi

if [[ "$ack_idx" -eq "$pending_rotation_idx" ]]; then
  new_pos=$(( (rotation_pos + 1) % ${#rotation_reminder_slots[@]} ))
  write_state "-1" "-1" "$new_pos"
  exit 0
fi

emit_deny "$pending_rotation_idx" \
  "Subject is clean, but the '#ack-rule$((pending_rotation_idx + 1))' bash comment is missing." \
  "Required: add '# ack-rule$((pending_rotation_idx + 1))' as a trailing bash comment to confirm you read the rule." \
  "-1" "$pending_rotation_idx" "$rotation_pos"
