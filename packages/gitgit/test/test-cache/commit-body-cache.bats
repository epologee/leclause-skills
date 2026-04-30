#!/usr/bin/env bats
# commit-body-cache.bats: commit-body.sh guard integration with cache enabled.
# Tests that GITGIT_TEST_CACHE_REQUIRED=1 causes the guard to block commits
# whose Tests trailer paths have no cache entry, and allows them when entries
# are present.
#
# Strategy: exercise validate_body directly (not the full guard dispatch) with
# the cache env set, using the same shim-based approach as validate-body-cache.bats.
# This avoids the complexity of standing up the full guard chain while still
# verifying the cache integration through the shared validate_body path.

load helpers

# ---------------------------------------------------------------------------
# Helper: invoke validate_body with cache controls.
# ---------------------------------------------------------------------------

_invoke_with_cache() {
  local file="$1"
  local cache_required="${2:-0}"
  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    export GITGIT_TEST_CACHE_REQUIRED='$cache_required'
    source '$CACHE_LIB'
    source '$VALIDATE_LIB'
    validate_body '$file'
  " 2>&1
}

_setup_standard_trailers() {
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(cat <<'TR'
Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
TR
)"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
}

_standard_body() {
  cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts in analytics.

Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
MSG
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "cache-required=1: no cache entry blocks with tests-cache-miss" {
  _setup_standard_trailers
  local file
  file=$(write_fixture "guard-miss.txt" "$(_standard_body)")

  run _invoke_with_cache "$file" "1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tests-cache-miss"* ]]
  [[ "$output" == *"spec/services/session_spec.rb"* ]]
}

@test "cache-required=1: green-only entry fails rtg check (red-then-green-evidence-missing)" {
  _setup_standard_trailers
  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '0'
  "

  local file
  file=$(write_fixture "guard-hit.txt" "$(_standard_body)")

  run _invoke_with_cache "$file" "1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"red-then-green-evidence-missing"* ]]
}

@test "cache-required=1: red-then-green sequence passes all checks" {
  _setup_standard_trailers
  local red_ts green_ts
  red_ts=$(ts_ago 300)
  green_ts=$(ts_ago 60)
  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '1' '$red_ts'
    test_cache_record_run 'spec/services/session_spec.rb' 'sha2' '0' '$green_ts'
  "

  local file
  file=$(write_fixture "guard-rtg-ok.txt" "$(_standard_body)")

  run _invoke_with_cache "$file" "1"
  [ "$status" -eq 0 ]
}

@test "cache-required=0: no cache entry, validate_body still passes" {
  _setup_standard_trailers
  local file
  file=$(write_fixture "guard-disabled.txt" "$(_standard_body)")

  # No cache entries recorded.
  run _invoke_with_cache "$file" "0"
  [ "$status" -eq 0 ]
}

@test "cache-required=1: expired green entry blocks (treated as missing)" {
  _setup_standard_trailers
  local old_ts
  old_ts=$(ts_ago 700)
  bash -c "
    export GITGIT_TEST_CACHE='$GITGIT_TEST_CACHE'
    source '$CACHE_LIB'
    test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '0' '$old_ts'
  "

  local file
  file=$(write_fixture "guard-expired.txt" "$(_standard_body)")

  run _invoke_with_cache "$file" "1"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tests-cache-miss"* ]]
}
