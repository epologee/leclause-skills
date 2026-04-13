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

assert_passes "premature: finish flag" \
  premature-interruption-guard.sh "$(msg "Alles klaar. 🏁")"

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

# --- Summary ---

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "${TOTAL}/${TOTAL} passed"
  exit 0
else
  echo "${PASS}/${TOTAL} passed, ${FAIL} failed"
  exit 1
fi
