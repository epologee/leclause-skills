#!/usr/bin/env bats
# red-then-green.bats: validate the query_red_then_green function.
# Order matters: red must precede green chronologically.

load helpers

@test "red before green within window: query_red_then_green returns 0" {
  local red_ts green_ts
  red_ts=$(ts_ago 300)
  green_ts=$(ts_ago 100)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1" "$red_ts"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha2" "0" "$green_ts"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 0 ]
}

@test "green only (no red): query_red_then_green returns 1" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "red only (no green): query_red_then_green returns 1" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "green before red (wrong order): query_red_then_green returns 1" {
  local green_ts red_ts
  green_ts=$(ts_ago 300)
  red_ts=$(ts_ago 100)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "0" "$green_ts"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha2" "1" "$red_ts"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "red before green but green outside window: returns 1" {
  # Red within window, green outside window (expired).
  local red_ts green_ts
  red_ts=$(ts_ago 400)
  green_ts=$(ts_ago 700)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1" "$red_ts"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha2" "0" "$green_ts"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}

@test "multiple reds then green: returns 0 (earliest red before green)" {
  local r1 r2 g
  r1=$(ts_ago 500)
  r2=$(ts_ago 300)
  g=$(ts_ago 100)

  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha1" "1" "$r1"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha2" "1" "$r2"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha3" "0" "$g"

  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 0 ]
}

@test "empty cache: query_red_then_green returns 1" {
  run invoke_cache_fn test_cache_query_red_then_green "spec/foo_spec.rb" "600"
  [ "$status" -eq 1 ]
}
