#!/usr/bin/env bats
# packages/gitgit/test/migration/parity.bats
#
# Proves that the migrated commit-subject and commit-format guards behave
# identically to the old dont-do-that guards in every observable contract:
#
#   1. A subject starting with "Fix " is denied with the [gitgit/commit-subject]
#      mnemonic (previously [dont-do-that/commit-rule]).
#   2. The ack-rule token format is unchanged: "# ack-rule12" still works.
#   3. The state file is read from the new path; old state is migrated forward.
#   4. A subject starting with "Address review" is denied with rule 2.
#   5. commit-format denials use [gitgit/commit-format] mnemonic.

GITGIT_DISPATCH="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/hooks/dispatch.sh"

pretool_bash() {
  local cmd="$1"
  jq -cn --arg c "$cmd" \
    '{hook_event_name:"PreToolUse", tool_name:"Bash", tool_input:{command:$c}}'
}

setup() {
  # Each test gets its own isolated state file.
  STATE_FILE="$(mktemp)"
  export GITGIT_COMMIT_RULE_STATE_FILE="$STATE_FILE"
  # Ensure no old-path variable leaks in.
  unset CLAUDE_COMMIT_RULE_STATE_FILE
}

teardown() {
  rm -f "$STATE_FILE"
}

# --- 1. Fix-prefix denied with gitgit mnemonic ---

@test "subject starting with Fix is denied with [gitgit/commit-subject]" {
  run bash -c "echo '$(pretool_bash 'git commit -m "Fix the typo"')' | bash '$GITGIT_DISPATCH' 2>&1 >/dev/null"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[gitgit/commit-subject\]'
  echo "$output" | grep -q 'Rule 1/14'
}

# --- 2. ack-rule token format unchanged ---

@test "ack-rule token format unchanged: ack-rule1 clears Fix violation on rewrite" {
  # First call establishes a pending violation for Fix.
  echo "$(pretool_bash 'git commit -m "Fix the typo"')" | bash "$GITGIT_DISPATCH" >/dev/null 2>/dev/null || true

  # Second call: clean subject + ack-rule1 must pass.
  run bash -c "echo '$(pretool_bash 'git commit -m "Use correct policy on read path" # ack-rule1')' | bash '$GITGIT_DISPATCH' 2>&1"
  [ "$status" -eq 0 ]
}

@test "ack-rule token format unchanged: ack-rule12 is accepted as a valid token" {
  # Advance rotation to slot 12 (idx 11, rule 12) by walking through earlier slots.
  # Slot order: 3 4 5 6 7 8 9 10 11 12 13 (0-indexed 0..10 in _DD_ROTATION_SLOTS).
  # Slot index 8 in the array is rule 12 (1-indexed). We need rp=8 in state file.
  # Write state directly: pv=-1 pr=-1 rp=8 (points to slot index 8 => rule index 11 => rule 12).
  printf '%s\n' '-1' '-1' '8' > "$STATE_FILE"

  # Clean commit should surface rule 12 reminder.
  run bash -c "echo '$(pretool_bash 'git commit -m "Introduce session context guard"')' | bash '$GITGIT_DISPATCH' 2>&1 >/dev/null"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q 'Rule 12/14'

  # Now ack-rule12 should pass it.
  run bash -c "echo '$(pretool_bash 'git commit -m "Introduce session context guard" # ack-rule12')' | bash '$GITGIT_DISPATCH' 2>&1"
  [ "$status" -eq 0 ]
}

# --- 3. State file migration: old path copied to new path ---

@test "old commit-rule-state is migrated to new gitgit-commit-rule-state on first run" {
  OLD_STATE="$(mktemp)"
  NEW_STATE="$(mktemp)"
  rm -f "$NEW_STATE"  # simulate new path not yet existing

  # Write a clean rotation state to the old file.
  printf '%s\n' '-1' '-1' '0' > "$OLD_STATE"

  export CLAUDE_COMMIT_RULE_STATE_FILE="$OLD_STATE"
  export GITGIT_COMMIT_RULE_STATE_FILE="$NEW_STATE"

  # Trigger the guard; it should copy OLD to NEW.
  echo "$(pretool_bash 'git commit -m "Use policy on the read path"')" \
    | bash "$GITGIT_DISPATCH" >/dev/null 2>/dev/null || true

  [ -f "$NEW_STATE" ]

  rm -f "$OLD_STATE" "$NEW_STATE"
  unset CLAUDE_COMMIT_RULE_STATE_FILE
  export GITGIT_COMMIT_RULE_STATE_FILE="$STATE_FILE"
}

# --- 4. "Address review" denied with rule 2 ---

@test "subject starting with Address review is denied with Rule 2/14" {
  run bash -c "echo '$(pretool_bash 'git commit -m "Address review findings"')' | bash '$GITGIT_DISPATCH' 2>&1 >/dev/null"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[gitgit/commit-subject\]'
  echo "$output" | grep -q 'Rule 2/14'
}

# --- 5. commit-format uses [gitgit/commit-format] mnemonic ---

@test "subject over 72 chars is denied with [gitgit/commit-format] mnemonic" {
  run bash -c "echo '$(pretool_bash 'git commit -m "Override the upstream defaults that nudge multi-line commits into a heredoc form."')' | bash '$GITGIT_DISPATCH' 2>&1 >/dev/null"
  [ "$status" -eq 2 ]
  echo "$output" | grep -q '\[gitgit/commit-format\]'
  echo "$output" | grep -q 'max 72'
}
