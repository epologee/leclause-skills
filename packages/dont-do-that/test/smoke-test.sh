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

assert_outputs() {
  local description="$1"
  local script="$2"
  local input="$3"
  local expected="$4"
  local output
  output=$(echo "$input" | bash "${HOOKS_DIR}/${script}" 2>/dev/null)
  if echo "$output" | grep -qF -- "$expected"; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [expected '${expected}']: ${description}"
    echo "  output: ${output:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

assert_silent() {
  local description="$1"
  local script="$2"
  local input="$3"
  local output
  output=$(echo "$input" | bash "${HOOKS_DIR}/${script}" 2>/dev/null)
  if [ -z "$output" ]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [silent expected]: ${description}"
    echo "  output: ${output}"
    FAIL=$((FAIL + 1))
  fi
}

cmd() {
  echo "{\"tool_input\":{\"command\":\"${1}\"}}"
}

# Deterministic rotation index file so tests do not touch real state.
TMP_INDEX=$(mktemp)
export CLAUDE_COMMIT_RULE_INDEX_FILE="$TMP_INDEX"

assert_silent "rotator: non-commit passes silent" \
  commit-message-rule-rotator.sh "$(cmd "git status")"

assert_silent "rotator: gh commit (not git) passes silent" \
  commit-message-rule-rotator.sh "$(cmd "gh pr create")"

assert_outputs "rotator: activity-word Add surfaces rule 1" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Add authentication middleware\\\"")" \
  "[1/14]"

assert_outputs "rotator: activity-word Fix highlights first word" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Fix the typo\\\"")" \
  "starts with 'Fix'"

assert_outputs "rotator: trigger-as-reason Address findings surfaces rule 2" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Address pride findings\\\"")" \
  "[2/14]"

assert_outputs "rotator: trigger-as-reason Fix review comments surfaces rule 2" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Fix review comments from reviewer\\\"")" \
  "[2/14]"

echo 0 > "$TMP_INDEX"
assert_outputs "rotator: clean subject at index 0 surfaces a rule" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Use policy scope on the read path\\\"")" \
  "[1/14]"

assert_outputs "rotator: second clean subject rotates to a different rule" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Require session context on the create path\\\"")" \
  "[2/14]"

assert_outputs "rotator: subject echoed back in reminder" \
  commit-message-rule-rotator.sh "$(cmd "git commit -m \\\"Raise CalculationError on missing total key\\\"")" \
  "Raise CalculationError on missing total key"

rm -f "$TMP_INDEX"
unset CLAUDE_COMMIT_RULE_INDEX_FILE

# --- Summary ---

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "${TOTAL}/${TOTAL} passed"
  exit 0
else
  echo "${PASS}/${TOTAL} passed, ${FAIL} failed"
  exit 1
fi
