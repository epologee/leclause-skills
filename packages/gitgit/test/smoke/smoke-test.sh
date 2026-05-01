#!/bin/bash
# Smoke test suite for the gitgit dispatcher. Every case routes through
# hooks/dispatch.sh with an explicit hook_event_name, so the test covers
# the real path Claude Code takes at runtime.
# Run from the repo root or from the plugin root:
#   bash packages/gitgit/test/smoke/smoke-test.sh
# Exit code 0 = all pass, 1 = failures.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DISPATCH="${SCRIPT_DIR}/../../hooks/dispatch.sh"
PASS=0
FAIL=0

pretool_bash() {
  local cmd="$1"
  jq -cn --arg c "$cmd" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'
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
  if ! echo "$stderr_content" | grep -q '\[gitgit/'; then
    echo "FAIL [missing gitgit mnemonic prefix]: ${description}"
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

expect_warning_subject() {
  local description="$1" payload="$2"
  local out
  out=$(echo "$payload" | bash "$DISPATCH" 2>/dev/null)
  if echo "$out" | grep -q '"additionalContext"' \
     && echo "$out" | grep -q '\[gitgit/commit-format\]' \
     && echo "$out" | grep -q '"hookEventName":"PreToolUse"'; then
    PASS=$((PASS + 1))
  else
    echo "FAIL [PreToolUse additionalContext expected]: ${description}"
    echo "  output: ${out:-<empty>}"
    FAIL=$((FAIL + 1))
  fi
}

# Helper: run a commit through dispatch expecting deny (exit 2), don't count it
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

# --- State file setup ---
# Use a temp file so tests don't pollute the real rotation state.
TMP_STATE=$(mktemp)
export GITGIT_COMMIT_RULE_STATE_FILE="$TMP_STATE"
reset_state() { : > "$TMP_STATE"; }

# --- commit-format: subject too long ---

reset_state
expect_deny "format: subject over 72 chars is denied" \
  "$(pretool_bash 'git commit -m "Override the upstream defaults that nudge multi-line commits into a heredoc form."')" \
  "max 72"

# --- commit-format: multi-line without blank separator ---

reset_state
heredoc_no_blank=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Use policy on the read path
Body line right after subject without a blank line.
EOF
)" # ack-rule4:essentie
INNER_CMD
)
heredoc_no_blank_json=$(jq -cn --arg cmd "$heredoc_no_blank" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "format: multi-line without blank separator is denied" \
  "$heredoc_no_blank_json" \
  "blank line"

# --- commit-format: valid multi-line heredoc passes ---
# Body includes Slice/Tests/Red-then-green trailers so commit-body block-mode
# is satisfied. The smoke test focuses on commit-format behaviour; the body
# schema is orthogonal and we ship a compliant body here.

reset_state
heredoc_clean=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Use policy on the read path

The body explains the why in two short sentences.
Wrap each line at the seventy-two char ceiling.

Slice: docs-only
EOF
)" # ack-rule4:essentie
INNER_CMD
)
heredoc_clean_json=$(jq -cn --arg cmd "$heredoc_clean" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "format: valid heredoc with blank separator passes" \
  "$heredoc_clean_json"

# --- commit-format: aspirational warning (51-72 chars) ---

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_warning_subject "format: 58-char subject emits aspirational warning" \
  "$(pretool_bash 'git commit -m "Cap retry budget so the workflow no longer hammers backend" # ack-rule4:essentie')"

# --- commit-subject: rule 1 (activity-word start) ---

reset_state
expect_deny "subject: activity-word Fix denies with rule 1" \
  "$(pretool_bash 'git commit -m "Fix the typo"')" \
  "Rule 1/14"

reset_state
expect_deny "subject: activity-word Add denies with rule 1" \
  "$(pretool_bash 'git commit -m "Add authentication middleware"')" \
  "Rule 1/14"

reset_state
expect_deny "subject: -am flag still detects activity-word violation" \
  "$(pretool_bash 'git commit -am "Add logging"')" \
  "Rule 1/14"

reset_state
expect_deny "subject: --message= still detects activity-word violation" \
  "$(pretool_bash 'git commit --message="Fix typo"')" \
  "Rule 1/14"

# --- commit-subject: rule 2 (trigger phrasing) ---

reset_state
expect_deny "subject: Address review phrasing denies with rule 2" \
  "$(pretool_bash 'git commit -m "Address review findings"')" \
  "Rule 2/14"

reset_state
expect_deny "subject: Apply PR comments denies with rule 2" \
  "$(pretool_bash 'git commit -m "Apply PR comments"')" \
  "Rule 2/14"

# --- commit-subject: ack-rule token format unchanged ---

reset_state
run "$(pretool_bash 'git commit -m "Fix typo"')"
expect_allow "subject: ack-rule1 on clean rewrite clears violation" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule1:gedrag')"

reset_state
run "$(pretool_bash 'git commit -m "Address pride findings"')"
expect_allow "subject: ack-rule2 on clean rewrite clears trigger violation" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule2:effect')"

reset_state
expect_deny "subject: ack-rule on still-violating subject denies with overtreedt nog" \
  "$(pretool_bash 'git commit -m "Fix typo" # ack-rule1:gedrag')" \
  "overtreedt nog"

# --- commit-subject: rotation reminder ---

reset_state
expect_deny "subject: clean subject in fresh state surfaces rule 4" \
  "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
  "Rule 4/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_allow "subject: clean subject with correct ack passes rotation" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule4:essentie')"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
expect_deny "subject: wrong ack number still denies pending rule 4" \
  "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule9:solist')" \
  "Rule 4/14"

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
run "$(pretool_bash 'git commit -m "Use policy on the read path" # ack-rule4:essentie')" 0
expect_deny "subject: rotation advances after pass to rule 5" \
  "$(pretool_bash 'git commit -m "Require session context on create"')" \
  "Rule 5/14"

# --- commit-subject: editor-mode blocked ---

reset_state
expect_deny "subject: editor-mode commit without subject denies with instruction" \
  "$(pretool_bash 'git commit')" \
  "Pass inline"

# --- commit-subject: non-commit commands pass through ---

reset_state
expect_allow "subject: non-commit git command passes silent" \
  "$(pretool_bash 'git status')"

reset_state
expect_allow "subject: gh pr create passes silent" \
  "$(pretool_bash 'gh pr create')"

# --- ack token stripped from heredoc body (no gaming) ---

reset_state
run "$(pretool_bash 'git commit -m "Use policy on the read path"')"
heredoc_body_cmd=$(cat <<'INNER_CMD'
git commit -m "$(cat <<'EOF'
Clean subject

# ack-rule4:essentie
EOF
)"
INNER_CMD
)
heredoc_body_json=$(jq -cn --arg cmd "$heredoc_body_cmd" \
  '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$cmd}}')
expect_deny "subject: ack inside heredoc body is stripped, does not count" \
  "$heredoc_body_json" \
  "Rule 4/14"

# --- state file migration: old path copied to new path on first run ---

reset_state
OLD_STATE=$(mktemp)
NEW_STATE=$(mktemp)
rm -f "$NEW_STATE"  # simulate new file not yet existing
printf '%s\n' '-1' '-1' '0' > "$OLD_STATE"
export CLAUDE_COMMIT_RULE_STATE_FILE="$OLD_STATE"
export GITGIT_COMMIT_RULE_STATE_FILE="$NEW_STATE"
echo "$(pretool_bash 'git commit -m "Use policy on the read path"')" | bash "$DISPATCH" >/dev/null 2>/dev/null || true
if [[ -f "$NEW_STATE" ]]; then
  PASS=$((PASS + 1))
else
  echo "FAIL [migration]: old state file not copied to new path"
  FAIL=$((FAIL + 1))
fi
rm -f "$OLD_STATE" "$NEW_STATE"
unset CLAUDE_COMMIT_RULE_STATE_FILE

# Restore temp state for remaining tests
export GITGIT_COMMIT_RULE_STATE_FILE="$TMP_STATE"
reset_state

# --- Cleanup ---

rm -f "$TMP_STATE"
unset GITGIT_COMMIT_RULE_STATE_FILE

# --- Summary ---

TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "${TOTAL}/${TOTAL} passed"
  exit 0
else
  echo "${PASS}/${TOTAL} passed, ${FAIL} failed"
  exit 1
fi
