#!/bin/bash
# Smoke test suite for the dont-do-that dispatcher. Every case routes
# through hooks/dispatch.sh with an explicit hook_event_name, so the test
# covers the real path Claude Code takes at runtime.
# Run from the plugin root: bash test/smoke-test.sh
# Exit code 0 = all pass, 1 = failures.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISPATCH="${SCRIPT_DIR}/../hooks/dispatch.sh"
PASS=0
FAIL=0

stop_payload() {
  local text="$1" active="${2:-false}"
  jq -cn --arg t "$text" --argjson a "$active" \
    '{hook_event_name:"Stop", last_assistant_message:$t, stop_hook_active:$a}'
}

pretool_bash() {
  local cmd="$1"
  jq -cn --arg c "$cmd" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'
}

posttool_edit() {
  local file="$1" content="$2"
  jq -cn --arg f "$file" --arg c "$content" \
    '{hook_event_name:"PostToolUse", tool_name:"Edit", tool_input:{file_path:$f, new_string:$c}}'
}

expect_block() {
  local description="$1" payload="$2"
  local out
  out=$(echo "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"decision":"block"'; then
    # Verify uniform mnemonic prefix.
    if echo "$out" | grep -q '\[dont-do-that/'; then
      PASS=$((PASS + 1))
    else
      echo "FAIL [missing mnemonic prefix]: ${description}"
      echo "  output: ${out}"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "FAIL [block expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

expect_pass() {
  local description="$1" payload="$2"
  local out
  out=$(echo "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"decision":"block"'; then
    echo "FAIL [pass expected]: ${description}"
    echo "  output: ${out}"
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
}

expect_deny() {
  local description="$1" payload="$2" expected_substring="${3:-}"
  local stderr_file exit_code stderr_content
  stderr_file=$(mktemp)
  echo "$payload" | bash "$DISPATCH" >/dev/null 2>"$stderr_file"
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
  if ! echo "$stderr_content" | grep -q '\[dont-do-that/'; then
    echo "FAIL [missing mnemonic prefix]: ${description}"
    echo "  stderr: ${stderr_content}"
    FAIL=$((FAIL + 1))
    return
  fi
  if [ -n "$expected_substring" ] && ! echo "$stderr_content" | grep -qF -- "$expected_substring"; then
    echo "FAIL [expected '${expected_substring}']: ${description}"
    echo "  stderr: ${stderr_content}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

expect_allow() {
  local description="$1" payload="$2"
  local stderr_file exit_code
  stderr_file=$(mktemp)
  echo "$payload" | bash "$DISPATCH" >/dev/null 2>"$stderr_file"
  exit_code=$?
  rm -f "$stderr_file"
  if [ "$exit_code" -ne 0 ]; then
    echo "FAIL [allow expected exit 0]: ${description}"
    echo "  exit: ${exit_code}"
    FAIL=$((FAIL + 1))
    return
  fi
  PASS=$((PASS + 1))
}

expect_context() {
  local description="$1" payload="$2"
  local out
  out=$(echo "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"additionalContext"'; then
    if echo "$out" | grep -q '\[dont-do-that/dash\]'; then
      PASS=$((PASS + 1))
    else
      echo "FAIL [missing dash mnemonic]: ${description}"
      echo "  output: ${out}"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "FAIL [additionalContext expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

# --- premature-interruption ---

expect_block "premature: no escape hatch" \
  "$(stop_payload "Ik heb het aangepast.")"

expect_pass "premature: finish flag with substantive sentence" \
  "$(stop_payload "Beide hooks gefixt en de syntax check slaagt nu. 🏁")"

expect_block "premature: bare finish flag" \
  "$(stop_payload "🏁")"

expect_block "premature: flag without substantive sentence" \
  "$(stop_payload "Klaar 🏁")"

expect_pass "premature: question hands off to compliance" \
  "$(stop_payload "Wat bedoel je precies?")"

expect_block "premature: flag + question is contradiction" \
  "$(stop_payload "Of zal ik hem starten? 🏁")"

expect_block "premature: flag + question separated" \
  "$(stop_payload "Wil je dit nog? Ja hoor. 🏁")"

expect_pass "premature: WIP hatch" \
  "$(stop_payload "Bezig met hooks 🚧")"

expect_pass "premature: mutex skips" \
  "$(stop_payload "Iets." true)"

# --- compliance-reflex ---

expect_block "compliance: shall I question" \
  "$(stop_payload "Wil je dat ik dit nog aanpas?")"

expect_block "compliance: preference question" \
  "$(stop_payload "Wat heeft je voorkeur?")"

expect_block "compliance: English shall I" \
  "$(stop_payload "Should I update this?")"

expect_pass "compliance: compass escape" \
  "$(stop_payload "🧭 Andere richting nodig?")"

expect_pass "compliance: genuine question" \
  "$(stop_payload "Bedoel je de header of de footer?")"

expect_pass "compliance: WIP hatch" \
  "$(stop_payload "Zal ik dit fixen? 🚧")"

expect_pass "compliance: no question mark" \
  "$(stop_payload "Ik heb de configuratie aangepast en alle testen blijven groen. 🏁")"

# --- cache-excuse ---

expect_block "cache: browser cache blame" \
  "$(stop_payload "Dit komt door de browser cache.")"

expect_block "cache: hard refresh suggestion" \
  "$(stop_payload "Probeer Cmd+Shift+R.")"

expect_pass "cache: no cache mention" \
  "$(stop_payload "Het probleem zit in de router config en niet elders. 🏁")"

expect_pass "cache: WIP hatch" \
  "$(stop_payload "Browser cache issue 🚧")"

expect_pass "cache: mutex skips" \
  "$(stop_payload "Browser cache." true)"

# --- false-claims ---

expect_block "false-claims: pre-existing" \
  "$(stop_payload "Dit is een pre-existing failure.")"

expect_block "false-claims: already broken" \
  "$(stop_payload "Dit was al stuk.")"

expect_block "false-claims: known issue" \
  "$(stop_payload "Dit is een known issue.")"

expect_pass "false-claims: clean text" \
  "$(stop_payload "De test faalt door een typo in de config van middleware. 🏁")"

expect_pass "false-claims: WIP hatch" \
  "$(stop_payload "Pre-existing issue 🚧")"

expect_block "false-claims: ignores mutex (always runs)" \
  "$(stop_payload "Dit is een pre-existing failure." true)"

# --- verification-delegation ---
# Every case includes a substantive sentence + 🏁 so the premature-interruption
# guard in the chain hands off to verify instead of blocking first.

expect_block "verification: unproven claim" \
  "$(stop_payload "Ik heb de endpoint niet geraakt maar dit zou nu moeten werken. 🏁")"

expect_block "verification: asks user to check" \
  "$(stop_payload "De wijziging staat in het bestand. Check of het werkt. 🏁")"

expect_block "verification: asks user to refresh" \
  "$(stop_payload "Ik heb de styling aangepast. Refresh de pagina. 🏁")"

expect_block "verification: English claim" \
  "$(stop_payload "I changed the config. This should now work. 🏁")"

expect_pass "verification: Geverifieerd escape" \
  "$(stop_payload "Geverifieerd: screenshot bevestigt de nieuwe styling werkt. 🏁")"

expect_pass "verification: clean text" \
  "$(stop_payload "De wijziging staat in het bestand en de testen blijven groen. 🏁")"

expect_pass "verification: WIP hatch" \
  "$(stop_payload "Zou moeten werken 🚧")"

expect_pass "verification: mutex skips" \
  "$(stop_payload "Zou moeten werken. 🏁" true)"

# --- block-followup-without-issue ---

expect_deny "followup: follow-up taal in gh api body" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Komt in een follow-up PR"')" \
  "followup"

expect_deny "followup: buiten-scope phrasing" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Buiten scope van deze mission"')" \
  "followup"

expect_allow "followup: Bewust uitgesteld escape" \
  "$(pretool_bash 'gh api repos/foo/bar/issues --field body="Bewust uitgesteld: volgt in een follow-up PR"')"

expect_allow "followup: non-gh command passes" \
  "$(pretool_bash 'echo follow-up')"

# --- block-inline-dashes ---
# The awk dash-detect needs an em-dash in a non-code line. We use printf
# to inject the raw byte so the literal stays out of the file.
EMDASH="$(printf '\xe2\x80\x94')"
expect_context "dash: em-dash in Edit new_string" \
  "$(posttool_edit "/tmp/x.md" "Some prose with ${EMDASH} dash here")"

expect_allow "dash: clean Edit new_string passes silent" \
  "$(posttool_edit "/tmp/x.md" "No dash here.")"

# --- commit-message-rule-rotator ---

TMP_STATE=$(mktemp)
export CLAUDE_COMMIT_RULE_STATE_FILE="$TMP_STATE"
reset_state() { : > "$TMP_STATE"; }

run() {
  local expected="${2:-2}" actual
  echo "$1" | bash "$DISPATCH" >/dev/null 2>/dev/null
  actual=$?
  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL [run: expected exit ${expected}, got ${actual}]"
    echo "  input: $1"
    FAIL=$((FAIL + 1))
  fi
}

reset_state
expect_allow "rotator: non-commit passes silent" \
  "$(pretool_bash 'git status')"

reset_state
expect_allow "rotator: gh pr create passes silent" \
  "$(pretool_bash 'gh pr create')"

reset_state
expect_deny "rotator: activity-word Add denies with rule 1" \
  "$(pretool_bash 'git commit -m "Add authentication middleware"')" \
  "Rule 1/14"

reset_state
expect_deny "rotator: activity-word Fix denies with rule 1" \
  "$(pretool_bash 'git commit -m "Fix the typo"')" \
  "Rule 1/14"

reset_state
expect_deny "rotator: activity-word with matching ack but no rewrite still denies" \
  "$(pretool_bash 'git commit -m "Fix typo" # ack-rule1')" \
  "overtreedt nog"

reset_state
run "$(pretool_bash 'git commit -m "Fix typo"')"
expect_allow "rotator: activity-word rewrite with ack-rule1 passes" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule1')"

reset_state
expect_deny "rotator: trigger Address findings denies with rule 2" \
  "$(pretool_bash 'git commit -m "Address pride findings"')" \
  "Rule 2/14"

reset_state
expect_deny "rotator: trigger Apply PR comments denies with rule 2" \
  "$(pretool_bash 'git commit -m "Apply PR comments"')" \
  "Rule 2/14"

reset_state
run "$(pretool_bash 'git commit -m "Address pride findings"')"
expect_allow "rotator: trigger rewrite with ack-rule2 passes" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule2')"

reset_state
expect_deny "rotator: clean subject fresh state surfaces rule 3" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 3/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "rotator: clean subject with ack-rule3 passes" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule3')"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_deny "rotator: wrong ack number still denies pending rule" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule9')" \
  "Rule 3/14"

reset_state
expect_deny "rotator: -am extracts subject for violation" \
  "$(pretool_bash 'git commit -am "Add logging"')" \
  "Rule 1/14"

reset_state
expect_deny "rotator: --message= extracts subject for violation" \
  "$(pretool_bash 'git commit --message="Fix typo"')" \
  "Rule 1/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_deny "rotator: ack inside quoted subject is stripped, still denies" \
  "$(pretool_bash 'git commit -m "subject with # ack-rule3 inside"')" \
  "Rule 3/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
run "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule3')" 0
expect_deny "rotator: rotation advances after pass to rule 4" \
  "$(pretool_bash 'git commit -m "Require session context on create"')" \
  "Rule 4/14"

reset_state
run "$(pretool_bash 'git commit -m "Fix typo"')"
run "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule1')" 0
expect_deny "rotator: violation pass does not advance rotation, next clean still hits rule 3" \
  "$(pretool_bash 'git commit -m "Require session context on create"')" \
  "Rule 3/14"

reset_state
expect_deny "rotator: subject is echoed in deny message" \
  "$(pretool_bash 'git commit -m "Raise CalculationError on missing total key"')" \
  "Raise CalculationError on missing total key"

reset_state
expect_deny "rotator: editor-mode git commit without subject denies with instruction" \
  "$(pretool_bash 'git commit')" \
  "Pass inline"

reset_state
printf 'garbage\nmore garbage\nnot a number\n' > "$TMP_STATE"
expect_deny "rotator: corrupt state file resets to defaults and denies with rotation rule 3" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 3/14"

reset_state
printf '99\n99\n99\n' > "$TMP_STATE"
expect_deny "rotator: out-of-range state indices are clamped to rotation rule 3" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 3/14"

reset_state
printf '2\n0\n-5\n' > "$TMP_STATE"
expect_deny "rotator: pending_violation outside {-1,0,1} is clamped to -1" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 3/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_deny "rotator: ack without leading whitespace does not count as ack" \
  "$(pretool_bash 'git commit -m "Use policy"bogus#ack-rule3')" \
  "Rule 3/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
heredoc_body_cmd=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Clean subject

# ack-rule3
EOF
)"
INNER_CMD
)
heredoc_body_json=$(jq -cn --arg cmd "$heredoc_body_cmd" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "rotator: ack inside heredoc body is stripped, does not count as ack" \
  "$heredoc_body_json" \
  "Rule 3/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
run "$(pretool_bash 'git commit -m "Fix typo"')"
run "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule1')" 0
expect_deny "rotator: violation + rewrite preserves pending rotation rule 3" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 3/14"

# --- commit-format ---

# Format guard runs before commit-rule, so a format deny exits without ever
# touching the rotator state. Most cases below reset_state anyway to keep
# the rotator out of the picture for any passing case that would otherwise
# trip its rotation reminder.

reset_state
expect_deny "format: subject over 72 chars denies" \
  "$(pretool_bash 'git commit -m "Override the upstream defaults that nudge multi-line commits into a heredoc form."')" \
  "max 72"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "format: 27-char subject with ack passes" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule3')"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "format: 60-char aspirational subject still passes (no warn block)" \
  "$(pretool_bash 'git commit -m "Cap retry budget so the workflow no longer hammers backend" # ack-rule3')"

reset_state
expect_deny "format: subject over 72 denies even with ack present" \
  "$(pretool_bash 'git commit -m "Override the upstream defaults that nudge multi-line commits into a heredoc form." # ack-rule3')" \
  "max 72"

reset_state
heredoc_clean=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Use policy on the read path

The body explains the why in two short sentences.
Wrap each line at the seventy-two char ceiling.

[doublecheck]
EOF
)" # ack-rule3
INNER_CMD
)
heredoc_clean_json=$(jq -cn --arg cmd "$heredoc_clean" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "format: heredoc with body and blank separator passes" \
  "$heredoc_clean_json"

reset_state
heredoc_long_body=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Use policy on the read path

This body line is intentionally written so it goes well past the seventy two char ceiling on purpose.
EOF
)" # ack-rule3
INNER_CMD
)
heredoc_long_body_json=$(jq -cn --arg cmd "$heredoc_long_body" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "format: heredoc body line over 72 denies with line number" \
  "$heredoc_long_body_json" \
  "Body line 3"

reset_state
heredoc_no_blank=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Use policy on the read path
Body line right after subject without a blank line.
EOF
)" # ack-rule3
INNER_CMD
)
heredoc_no_blank_json=$(jq -cn --arg cmd "$heredoc_no_blank" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "format: heredoc without blank separator denies" \
  "$heredoc_no_blank_json" \
  "blank line"

reset_state
heredoc_long_subject=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
This subject is deliberately stretched far past the seventy two char ceiling.

Body.
EOF
)"
INNER_CMD
)
heredoc_long_subject_json=$(jq -cn --arg cmd "$heredoc_long_subject" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "format: heredoc subject over 72 denies before rotator runs" \
  "$heredoc_long_subject_json" \
  "Subject is"

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
