#!/usr/bin/env bats
# live-flow.bats: behavioural integration test for the full saw-red -> fix ->
# run-spec-green -> commit flow.
#
# This suite exercises the lib functions directly (no external git init, no
# real test runner) to verify the complete cache-based validation lifecycle:
#
#   1. log a RED entry (simulates /gitgit:saw-red)
#   2. log a GREEN entry (simulates /gitgit:run-spec passing)
#   3. validate a commit message with GITGIT_TEST_CACHE_REQUIRED=1 -> passes
#   4. same flow without the RED step -> fails red-then-green
#   5. no cache entries at all -> fails tests-cache-miss
#   6. cache disabled -> always passes

load helpers

SAW_RED_LIB="$SCRIPT_DIR/../../skills/saw-red/lib/saw-red.sh"

# ---------------------------------------------------------------------------
# Helper: run validate_body in a subshell with cache env applied.
# Uses the git shim from helpers.bash (already on PATH via setup()).
# ---------------------------------------------------------------------------

_validate_with_cache() {
  local msg_file="$1"
  local cache_required="${2:-1}"
  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    export GITGIT_TEST_CACHE_REQUIRED='$cache_required'
    source '$CACHE_LIB'
    source '$VALIDATE_LIB'
    validate_body '$msg_file'
  " 2>&1
}

# ---------------------------------------------------------------------------
# Standard commit message fixture used across all flow tests.
# ---------------------------------------------------------------------------

_flow_msg() {
  cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in analytics.

Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
MSG
}

_setup_trailers() {
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(cat <<'TR'
Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
TR
)"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
}

# ---------------------------------------------------------------------------
# Helper: record a cache entry directly via the lib.
# ---------------------------------------------------------------------------

_record() {
  local path="$1" sha="$2" code="$3" ts="${4:-}"
  if [[ -n "$ts" ]]; then
    bash -c "
      export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
      source '$CACHE_LIB'
      test_cache_record_run '$path' '$sha' '$code' '$ts'
    "
  else
    bash -c "
      export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
      source '$CACHE_LIB'
      test_cache_record_run '$path' '$sha' '$code'
    "
  fi
}

# ---------------------------------------------------------------------------
# Test 1: full happy-path flow
# ---------------------------------------------------------------------------

@test "live-flow: saw-red then green then commit with cache required passes" {
  _setup_trailers

  local red_ts green_ts
  red_ts=$(ts_ago 300)
  green_ts=$(ts_ago 60)

  # Simulate /gitgit:saw-red.
  _record "spec/services/session_spec.rb" "sha_red" "1" "$red_ts"

  # Simulate /gitgit:run-spec (green).
  _record "spec/services/session_spec.rb" "sha_green" "0" "$green_ts"

  local msg_file
  msg_file=$(write_fixture "flow-happy.txt" "$(_flow_msg)")

  run _validate_with_cache "$msg_file" "1"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Test 2: green-only flow (no saw-red step) -> red-then-green fails
# ---------------------------------------------------------------------------

@test "live-flow: green without prior red fails red-then-green check" {
  _setup_trailers

  # Only a green entry; no red.
  _record "spec/services/session_spec.rb" "sha1" "0"

  local msg_file
  msg_file=$(write_fixture "flow-no-red.txt" "$(_flow_msg)")

  run _validate_with_cache "$msg_file" "1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"red-then-green-evidence-missing"* ]]
}

# ---------------------------------------------------------------------------
# Test 3: no cache entries at all -> tests-cache-miss
# ---------------------------------------------------------------------------

@test "live-flow: no cache entries fails with tests-cache-miss" {
  _setup_trailers

  local msg_file
  msg_file=$(write_fixture "flow-empty.txt" "$(_flow_msg)")

  run _validate_with_cache "$msg_file" "1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tests-cache-miss"* ]]
}

# ---------------------------------------------------------------------------
# Test 4: cache disabled -> always passes (backwards compat)
# ---------------------------------------------------------------------------

@test "live-flow: cache disabled, no entries, commit passes" {
  _setup_trailers

  local msg_file
  msg_file=$(write_fixture "flow-disabled.txt" "$(_flow_msg)")

  run _validate_with_cache "$msg_file" "0"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Test 5: saw-red via lib function records correctly
# ---------------------------------------------------------------------------

@test "saw-red lib records a red entry in the cache" {
  run bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    source '$SAW_RED_LIB'
    saw_red_record 'spec/services/session_spec.rb'
  " 2>&1

  [ "$status" -eq 0 ]
  [[ "$output" == *"RED logged"* ]]

  # Verify the cache file has a red entry.
  run bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_query_red 'spec/services/session_spec.rb'
  " 2>&1

  [ "$status" -eq 0 ]
  [[ "$output" == *"|1"* ]]
}

# ---------------------------------------------------------------------------
# Test 6: test_cache_clear removes all entries
# ---------------------------------------------------------------------------

@test "test_cache_clear empties the cache" {
  _record "spec/services/session_spec.rb" "sha1" "0"
  _record "spec/models/user_spec.rb" "sha2" "1"

  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_clear
  "

  run bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_query_run 'spec/services/session_spec.rb'
  " 2>&1
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Test 7: test_cache_clear with pattern removes only matching lines
# ---------------------------------------------------------------------------

@test "test_cache_clear with pattern removes only matching entries" {
  _record "spec/services/session_spec.rb" "sha1" "0"
  _record "spec/models/user_spec.rb" "sha2" "0"

  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_clear 'spec/models/user_spec.rb'
  "

  # session_spec should still be present.
  run bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_query_run 'spec/services/session_spec.rb'
  " 2>&1
  [ "$status" -eq 0 ]

  # user_spec should be gone.
  run bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_query_run 'spec/models/user_spec.rb'
  " 2>&1
  [ "$status" -eq 1 ]
}
