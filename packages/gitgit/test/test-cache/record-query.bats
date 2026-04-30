#!/usr/bin/env bats
# record-query.bats: test_cache_record_run + test_cache_query_run round-trips.
# Verifies that recorded entries are retrieved, multiple entries pick the
# most recent green, and query_red works symmetrically.

load helpers

@test "record_run then query_run returns 0 for green entry" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "abc123" "0"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb"
  [ "$status" -eq 0 ]
  [[ "$output" == *"spec/foo_spec.rb"* ]]
  [[ "$output" == *"|0"* ]]
}

@test "record_run red then query_run returns 1 (no green)" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "abc123" "1"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb"
  [ "$status" -eq 1 ]
}

@test "query_run for unknown path returns 1" {
  run invoke_cache_fn test_cache_query_run "spec/nonexistent_spec.rb"
  [ "$status" -eq 1 ]
}

@test "multiple records for same path: query_run matches most recent green" {
  # Record an older green then a newer one; both should satisfy query_run.
  local old_ts
  old_ts=$(ts_ago 400)
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "tree1" "0" "$old_ts"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "tree2" "0"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb"
  [ "$status" -eq 0 ]
  # The matched line should be the more recent one (tree2).
  [[ "$output" == *"tree2"* ]]
}

@test "different spec paths are stored and queried independently" {
  run invoke_cache_fn test_cache_record_run "spec/a_spec.rb" "sha1" "0"
  run invoke_cache_fn test_cache_record_run "spec/b_spec.rb" "sha2" "1"

  run invoke_cache_fn test_cache_query_run "spec/a_spec.rb"
  [ "$status" -eq 0 ]

  run invoke_cache_fn test_cache_query_run "spec/b_spec.rb"
  [ "$status" -eq 1 ]
}

@test "query_red returns 0 for red entry" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "abc123" "2"
  run invoke_cache_fn test_cache_query_red "spec/foo_spec.rb"
  [ "$status" -eq 0 ]
  [[ "$output" == *"|2"* ]]
}

@test "query_red returns 1 when only green entries exist" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "abc123" "0"
  run invoke_cache_fn test_cache_query_red "spec/foo_spec.rb"
  [ "$status" -eq 1 ]
}

@test "cache file is created when it does not exist" {
  [[ ! -f "$GITGIT_TEST_CACHE" ]]
  run invoke_cache_fn test_cache_record_run "spec/new_spec.rb" "sha" "0"
  [ "$status" -eq 0 ]
  [[ -f "$GITGIT_TEST_CACHE" ]]
}
