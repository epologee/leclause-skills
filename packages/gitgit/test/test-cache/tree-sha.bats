#!/usr/bin/env bats
# tree-sha.bats: verify tree SHA is stored in cache entries.
# query_run matches on spec_path regardless of tree SHA (the SHA is recorded
# for diagnostic/warning use by commit-body.sh, not for filtering).

load helpers

@test "cache entry contains the tree SHA passed to record_run" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "cafebabe1234" "0"
  [ "$status" -eq 0 ]

  # The cache file should contain the SHA.
  grep -q "cafebabe1234" "$GITGIT_TEST_CACHE"
}

@test "query_run matches entry regardless of tree SHA value" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha_a" "0"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha_b" "0"

  # Both entries exist; query_run should still return 0.
  run invoke_cache_fn test_cache_query_run "spec/foo_spec.rb"
  [ "$status" -eq 0 ]
}

@test "different tree SHAs for same path are stored as separate entries" {
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha_x" "1"
  run invoke_cache_fn test_cache_record_run "spec/foo_spec.rb" "sha_y" "0"

  local line_count
  line_count=$(grep -c "spec/foo_spec.rb" "$GITGIT_TEST_CACHE" 2>/dev/null || printf '0')
  [ "$line_count" -eq 2 ]
}

@test "test_cache_tree_sha echoes the git write-tree output" {
  export GIT_SHIM_TREE_SHA="aabbccddeeff00112233445566778899aabbccdd"
  run invoke_cache_fn test_cache_tree_sha
  [ "$status" -eq 0 ]
  [[ "$output" == "aabbccddeeff00112233445566778899aabbccdd" ]]
}
