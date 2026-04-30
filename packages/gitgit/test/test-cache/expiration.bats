#!/usr/bin/env bats
# expiration.bats: verify cache window logic for query_run and query_red.

load helpers

@test "query_run within default 600s window returns 0" {
  # Record a green entry with a timestamp 300s ago (within 600s window).
  local ts
  ts=$(ts_ago 300)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0" "$ts"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb" "600"
  [ "$status" -eq 0 ]
}

@test "query_run outside default 600s window returns 1" {
  # Record a green entry with a timestamp 700s ago (outside 600s window).
  local ts
  ts=$(ts_ago 700)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0" "$ts"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "query_run with explicit max_age picks up entry within that window" {
  local ts
  ts=$(ts_ago 120)
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0" "$ts"

  # 60s window: too old.
  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb" "60"
  [ "$status" -eq 1 ]

  # 200s window: within.
  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb" "200"
  [ "$status" -eq 0 ]
}

@test "query_red outside window returns 1" {
  local ts
  ts=$(ts_ago 700)
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1" "$ts"

  run invoke_cache_fn test_cache_query_red "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "query_red within window returns 0" {
  local ts
  ts=$(ts_ago 100)
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1" "$ts"

  run invoke_cache_fn test_cache_query_red "spec/foo_spec.rb" "600"
  [ "$status" -eq 0 ]
}

@test "expired green entry does not satisfy query_run even if newer red exists" {
  # Old green (expired).
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0" "$(ts_ago 700)"
  # Recent red.
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha2" "1" "$(ts_ago 10)"

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}
