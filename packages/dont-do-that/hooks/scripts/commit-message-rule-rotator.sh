#!/bin/bash
set -euo pipefail

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

activity_regex='^(Fix|Improve|Update|Change|Refactor|Add|Extract|Move|Remove|Rename|Drop|Create|Clear)[[:space:]]'
trigger_regex='^(Address|Apply)[[:space:]]+.*(review|feedback|findings|comments|pride)'

selected_rule=""
shopt -s nocasematch
if [[ -n "$subject" ]] && [[ "$subject" =~ $trigger_regex ]]; then
  shopt -u nocasematch
  selected_rule="[2/14] ${rules[1]} Your subject references the trigger: '$subject'."
elif [[ -n "$subject" ]] && [[ "$subject" =~ $activity_regex ]]; then
  shopt -u nocasematch
  first_word="${BASH_REMATCH[1]}"
  selected_rule="[1/14] ${rules[0]} Your subject starts with '$first_word'."
else
  shopt -u nocasematch
  rule_rotation_slots=(0 1 4 0 6 1 2 3 0 5 6 7 4 1 10 8 9 11 12 13)
  index_file="${CLAUDE_COMMIT_RULE_INDEX_FILE:-$HOME/.claude/var/commit-rule-index}"
  mkdir -p "$(dirname "$index_file")"
  current=0
  if [[ -f "$index_file" ]]; then
    current=$(cat "$index_file")
    current=${current:-0}
  fi
  pos=$((current % ${#rule_rotation_slots[@]}))
  rule_idx=${rule_rotation_slots[$pos]}
  echo $((current + 1)) > "$index_file"
  selected_rule="[$((rule_idx + 1))/14] ${rules[$rule_idx]}"
fi

if [[ -n "$subject" ]]; then
  message=$(printf '=== commit rule reminder ===\nSubject: "%s"\nRule: %s\n============================' "$subject" "$selected_rule")
else
  message=$(printf '=== commit rule reminder ===\nRule: %s\n============================' "$selected_rule")
fi

jq -n --arg msg "$message" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": $msg
  }
}'

exit 0
