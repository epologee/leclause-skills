#!/bin/bash
# Smoke test suite for dont-do-that hooks.
# Run from the plugin root: bash test/smoke-test.sh
# Exit code 0 = all pass, 1 = failures.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="${SCRIPT_DIR}/../hooks/scripts"
PASS=0
FAIL=0

assert_blocks() {
  local description="$1"
  local script="$2"
  local input="$3"
  local output
  output=$(echo "$input" | bash "${HOOKS_DIR}/${script}" 2>/dev/null)
  if echo "$output" | grep -q '"decision":"block"'; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [block expected]: ${description}"
    echo "  output: ${output:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

assert_passes() {
  local description="$1"
  local script="$2"
  local input="$3"
  local output
  output=$(echo "$input" | bash "${HOOKS_DIR}/${script}" 2>/dev/null)
  if echo "$output" | grep -q '"decision":"block"'; then
    echo "FAIL [pass expected]: ${description}"
    echo "  output: ${output}"
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
}

msg() {
  local text="$1"
  local active="${2:-false}"
  echo "{\"last_assistant_message\":\"${text}\",\"stop_hook_active\":${active}}"
}

# --- premature-interruption-guard ---

assert_blocks "premature: no escape hatch" \
  premature-interruption-guard.sh "$(msg "Ik heb het aangepast.")"

assert_passes "premature: finish flag with substantive sentence" \
  premature-interruption-guard.sh "$(msg "Beide hooks gefixt en de syntax check slaagt nu. 🏁")"

assert_blocks "premature: bare finish flag" \
  premature-interruption-guard.sh "$(msg "🏁")"

assert_blocks "premature: flag without substantive sentence" \
  premature-interruption-guard.sh "$(msg "Klaar 🏁")"

assert_passes "premature: question hands off to compliance" \
  premature-interruption-guard.sh "$(msg "Wat bedoel je precies?")"

assert_blocks "premature: flag + question is contradiction" \
  premature-interruption-guard.sh "$(msg "Of zal ik hem starten? 🏁")"

assert_blocks "premature: flag + question separated" \
  premature-interruption-guard.sh "$(msg "Wil je dit nog? Ja hoor. 🏁")"

assert_passes "premature: WIP hatch" \
  premature-interruption-guard.sh "$(msg "Bezig met hooks 🚧")"

assert_passes "premature: mutex skips" \
  premature-interruption-guard.sh "$(msg "Iets." true)"

# --- compliance-reflex-guard ---

assert_blocks "compliance: shall I question" \
  compliance-reflex-guard.sh "$(msg "Wil je dat ik dit nog aanpas?")"

assert_blocks "compliance: preference question" \
  compliance-reflex-guard.sh "$(msg "Wat heeft je voorkeur?")"

assert_blocks "compliance: English shall I" \
  compliance-reflex-guard.sh "$(msg "Should I update this?")"

assert_passes "compliance: compass escape" \
  compliance-reflex-guard.sh "$(msg "🧭 Andere richting nodig?")"

assert_passes "compliance: genuine question" \
  compliance-reflex-guard.sh "$(msg "Bedoel je de header of de footer?")"

assert_passes "compliance: WIP hatch" \
  compliance-reflex-guard.sh "$(msg "Zal ik dit fixen? 🚧")"

assert_passes "compliance: no question mark" \
  compliance-reflex-guard.sh "$(msg "Ik heb het gefixt.")"

# --- cache-excuse-guard ---

assert_blocks "cache: browser cache blame" \
  cache-excuse-guard.sh "$(msg "Dit komt door de browser cache.")"

assert_blocks "cache: hard refresh suggestion" \
  cache-excuse-guard.sh "$(msg "Probeer Cmd+Shift+R.")"

assert_passes "cache: no cache mention" \
  cache-excuse-guard.sh "$(msg "Het probleem zit in de router.")"

assert_passes "cache: WIP hatch" \
  cache-excuse-guard.sh "$(msg "Browser cache issue 🚧")"

assert_passes "cache: mutex skips" \
  cache-excuse-guard.sh "$(msg "Browser cache." true)"

# --- false-claims-guard ---

assert_blocks "false-claims: pre-existing" \
  false-claims-guard.sh "$(msg "Dit is een pre-existing failure.")"

assert_blocks "false-claims: already broken" \
  false-claims-guard.sh "$(msg "Dit was al stuk.")"

assert_blocks "false-claims: known issue" \
  false-claims-guard.sh "$(msg "Dit is een known issue.")"

assert_passes "false-claims: clean text" \
  false-claims-guard.sh "$(msg "De test faalt door een typo in de config.")"

assert_passes "false-claims: WIP hatch" \
  false-claims-guard.sh "$(msg "Pre-existing issue 🚧")"

assert_blocks "false-claims: ignores mutex (always runs)" \
  false-claims-guard.sh "$(msg "Dit is een pre-existing failure." true)"

# --- verification-delegation-guard ---

assert_blocks "verification: unproven claim" \
  verification-delegation-guard.sh "$(msg "Dit zou nu moeten werken.")"

assert_blocks "verification: asks user to check" \
  verification-delegation-guard.sh "$(msg "Check of het werkt.")"

assert_blocks "verification: asks user to refresh" \
  verification-delegation-guard.sh "$(msg "Refresh de pagina.")"

assert_blocks "verification: English claim" \
  verification-delegation-guard.sh "$(msg "This should now work.")"

assert_passes "verification: Geverifieerd escape" \
  verification-delegation-guard.sh "$(msg "Geverifieerd: screenshot bevestigt het.")"

assert_passes "verification: clean text" \
  verification-delegation-guard.sh "$(msg "De wijziging staat in het bestand.")"

assert_passes "verification: WIP hatch" \
  verification-delegation-guard.sh "$(msg "Zou moeten werken 🚧")"

assert_passes "verification: mutex skips" \
  verification-delegation-guard.sh "$(msg "Zou moeten werken." true)"

# --- commit-message-rule-rotator ---

assert_denies() {
  local description="$1"
  local script="$2"
  local input="$3"
  local expected_stderr="${4:-}"
  local stderr_file stderr_content exit_code
  stderr_file=$(mktemp)
  echo "$input" | bash "${HOOKS_DIR}/${script}" >/dev/null 2>"$stderr_file"
  exit_code=$?
  stderr_content=$(cat "$stderr_file")
  rm -f "$stderr_file"
  if [ "$exit_code" -ne 2 ]; then
    echo "FAIL [deny expected exit 2]: ${description}"
    echo "  exit: ${exit_code}"
    echo "  stderr: ${stderr_content:-<empty>}"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ -n "$expected_stderr" ] && ! echo "$stderr_content" | grep -qF -- "$expected_stderr"; then
    echo "FAIL [expected stderr '${expected_stderr}']: ${description}"
    echo "  stderr: ${stderr_content}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

assert_allows() {
  local description="$1"
  local script="$2"
  local input="$3"
  local stderr_file stderr_content exit_code
  stderr_file=$(mktemp)
  echo "$input" | bash "${HOOKS_DIR}/${script}" >/dev/null 2>"$stderr_file"
  exit_code=$?
  stderr_content=$(cat "$stderr_file")
  rm -f "$stderr_file"
  if [ "$exit_code" -ne 0 ]; then
    echo "FAIL [allow expected exit 0]: ${description}"
    echo "  exit: ${exit_code}"
    echo "  stderr: ${stderr_content:-<empty>}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

cmd() {
  echo "{\"tool_input\":{\"command\":\"${1}\"}}"
}

run_hook() {
  local expected_exit="${2:-2}"
  local actual_exit
  echo "$1" | bash "${HOOKS_DIR}/commit-message-rule-rotator.sh" >/dev/null 2>/dev/null
  actual_exit=$?
  if [ "$actual_exit" -ne "$expected_exit" ]; then
    echo "FAIL [run_hook: expected exit ${expected_exit}, got ${actual_exit}]"
    echo "  input: ${1}"
    FAIL=$((FAIL + 1))
  fi
}

TMP_STATE=$(mktemp)
export CLAUDE_COMMIT_RULE_STATE_FILE="$TMP_STATE"

reset_state() { : > "$TMP_STATE"; }

reset_state
assert_allows "rotator: non-commit passes silent" \
  commit-message-rule-rotator.sh "$(cmd "git status")"

reset_state
assert_allows "rotator: gh pr create passes silent" \
  commit-message-rule-rotator.sh "$(cmd "gh pr create")"

reset_state
assert_denies "rotator: activity-word Add denies with rule 1" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Add authentication middleware\\\"")" \
  "Rule [1/14]"

reset_state
assert_denies "rotator: activity-word Fix denies with rule 1" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Fix the typo\\\"")" \
  "Rule [1/14]"

reset_state
assert_denies "rotator: activity-word with matching ack but no rewrite still denies" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Fix typo\\\" # ack-rule1")" \
  "subject still violates this rule"

reset_state
run_hook "$(cmd "git commit -m \\\"Fix typo\\\"")"
assert_allows "rotator: activity-word rewrite with ack-rule1 passes" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule1")"

reset_state
assert_denies "rotator: trigger Address findings denies with rule 2" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Address pride findings\\\"")" \
  "Rule [2/14]"

reset_state
assert_denies "rotator: trigger Apply PR comments denies with rule 2" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Apply PR comments\\\"")" \
  "Rule [2/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Address pride findings\\\"")"
assert_allows "rotator: trigger rewrite with ack-rule2 passes" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule2")"

reset_state
assert_denies "rotator: clean subject fresh state surfaces rule 3" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\"")" \
  "Rule [3/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
assert_allows "rotator: clean subject with ack-rule3 passes" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule3")"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
assert_denies "rotator: wrong ack number still denies pending rule" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule9")" \
  "Rule [3/14]"

reset_state
assert_denies "rotator: -am extracts subject for violation" \
  commit-message-rule-rotator.sh "$(cmd "git commit -am \\\"Add logging\\\"")" \
  "Rule [1/14]"

reset_state
assert_denies "rotator: --message= extracts subject for violation" \
  commit-message-rule-rotator.sh "$(cmd "git commit --message=\\\"Fix typo\\\"")" \
  "Rule [1/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
assert_denies "rotator: ack inside quoted subject is stripped, still denies" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"subject with # ack-rule3 inside\\\"")" \
  "Rule [3/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule3")" 0
assert_denies "rotator: rotation advances after pass to rule 4" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Require session context on create\\\"")" \
  "Rule [4/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Fix typo\\\"")"
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule1")" 0
assert_denies "rotator: violation pass does not advance rotation, next clean subject still hits rule 3" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Require session context on create\\\"")" \
  "Rule [3/14]"

reset_state
assert_denies "rotator: subject is echoed in deny message" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Raise CalculationError on missing total key\\\"")" \
  "Raise CalculationError on missing total key"

reset_state
assert_denies "rotator: editor-mode git commit without subject denies with instruction" \
  commit-message-rule-rotator.sh "$(cmd "git commit")" \
  "pass the subject inline"

reset_state
printf 'garbage\nmore garbage\nnot a number\n' > "$TMP_STATE"
assert_denies "rotator: corrupt state file resets to defaults and denies with rotation rule 3" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\"")" \
  "Rule [3/14]"

reset_state
printf '99\n99\n99\n' > "$TMP_STATE"
assert_denies "rotator: out-of-range state indices are clamped and hook falls back to rotation rule 3" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\"")" \
  "Rule [3/14]"

reset_state
printf '2\n0\n-5\n' > "$TMP_STATE"
assert_denies "rotator: pending_violation_idx outside {-1,0,1} is clamped to -1" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\"")" \
  "Rule [3/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
assert_denies "rotator: ack token without leading whitespace does not count as ack" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy\\\"bogus#ack-rule3")" \
  "Rule [3/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
heredoc_body_cmd=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Clean subject
# ack-rule3
EOF
)"
INNER_CMD
)
heredoc_body_json=$(jq -cn --arg cmd "$heredoc_body_cmd" '{tool_input:{command:$cmd}}')
assert_denies "rotator: ack inside heredoc body is stripped, does not count as ack" \
  commit-message-rule-rotator.sh "$heredoc_body_json" \
  "Rule [3/14]"

reset_state
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\"")"
run_hook "$(cmd "git commit -m \\\"Fix typo\\\"")"
run_hook "$(cmd "git commit -m \\\"Use policy on the read path\\\" # ack-rule1")" 0
assert_denies "rotator: violation + rewrite preserves pending rotation rule 3" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy on the read path\\\"")" \
  "Rule [3/14]"

rm -f "$TMP_STATE"
unset CLAUDE_COMMIT_RULE_STATE_FILE

# --- Summary ---

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "${TOTAL}/${TOTAL} passed"
  exit 0
else
  echo "${PASS}/${TOTAL} passed, ${FAIL} failed"
  exit 1
fi
