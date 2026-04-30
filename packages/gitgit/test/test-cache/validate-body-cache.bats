#!/usr/bin/env bats
# validate-body-cache.bats: validate-body.sh with GITGIT_TEST_CACHE_REQUIRED=1.
# Tests that the cache-miss and red-then-green evidence checks work inside the
# full validate_body function.

load helpers

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

_body() {
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

# Set the git shim to return our standard trailers so validate_body can parse
# the trailer block without a real git repo.
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
# Cache disabled (GITGIT_TEST_CACHE_REQUIRED=0): no cache check.
# ---------------------------------------------------------------------------

@test "cache-required=0: valid body without cache entry passes" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=0

  local file
  file=$(write_fixture "no-cache-needed.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Cache enabled (GITGIT_TEST_CACHE_REQUIRED=1)
# ---------------------------------------------------------------------------

@test "cache-required=1: missing cache entry fails with tests-cache-miss" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=1

  # No cache entry recorded.
  local file
  file=$(write_fixture "cache-miss.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tests-cache-miss"* ]]
  [[ "$output" == *"spec/services/session_spec.rb"* ]]
}

@test "cache-required=1: green-only entry still fails rtg check (needs red first)" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=1

  # Record only a green entry (no prior red).
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '0'"

  local file
  file=$(write_fixture "cache-hit.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"red-then-green-evidence-missing"* ]]
}

@test "cache-required=1: red-then-green sequence satisfies all cache checks" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=1

  local red_ts green_ts
  red_ts=$(ts_ago 300)
  green_ts=$(ts_ago 60)
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '1' '$red_ts'"
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha2' '0' '$green_ts'"

  local file
  file=$(write_fixture "cache-rtg-ok.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "cache-required=1: red-then-green=yes without red entry fails" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=1

  # Record only a green entry (no prior red).
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '0'"

  local file
  file=$(write_fixture "rtg-no-red.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"red-then-green-evidence-missing"* ]]
}

@test "cache-required=1: red before green satisfies red-then-green=yes" {
  _setup_trailers
  export GITGIT_TEST_CACHE_REQUIRED=1

  local red_ts green_ts
  red_ts=$(ts_ago 300)
  green_ts=$(ts_ago 60)
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha1' '1' '$red_ts'"
  bash -c "source '$CACHE_LIB'; test_cache_record_run 'spec/services/session_spec.rb' 'sha2' '0' '$green_ts'"

  local file
  file=$(write_fixture "rtg-ok.txt" "$(_body)")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}
