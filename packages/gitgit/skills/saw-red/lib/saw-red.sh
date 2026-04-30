#!/bin/bash
# packages/gitgit/skills/saw-red/lib/saw-red.sh
# Records a RED (failing) cache entry for a spec path.
# Called by /gitgit:saw-red when the operator observed a test failure outside
# /gitgit:run-spec (IDE run, terminal, CI) and wants the cache to reflect it.
#
# Public function:
#   saw_red_record <spec-path>  -> records entry, prints confirmation, exits 0

# Locate test-cache.sh relative to this file.
_SR_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
_SR_CACHE_LIB="$_SR_LIB_DIR/../../../hooks/lib/test-cache.sh"

if [[ -f "$_SR_CACHE_LIB" ]]; then
  # shellcheck source=../../../hooks/lib/test-cache.sh
  source "$_SR_CACHE_LIB"
fi

# ---------------------------------------------------------------------------
# saw_red_record <spec-path>
# ---------------------------------------------------------------------------
saw_red_record() {
  local spec_path="$1"

  if [[ -z "$spec_path" ]]; then
    printf 'saw-red: spec path argument is required\n' >&2
    exit 1
  fi

  if ! command -v test_cache_record_run >/dev/null 2>&1; then
    printf 'saw-red: test-cache.sh not loaded; cannot record entry\n' >&2
    exit 1
  fi

  # Capture staged tree SHA.
  local tree_sha
  tree_sha=$(test_cache_tree_sha 2>/dev/null || git write-tree 2>/dev/null || printf 'unknown')

  # Record red run (exit code 1).
  test_cache_record_run "$spec_path" "$tree_sha" "1"

  # Print confirmation.
  local cache_file
  cache_file=$(test_cache_path)
  local last_line
  last_line=$(tail -1 "$cache_file" 2>/dev/null || printf '')

  printf 'RED logged for %s\n' "$spec_path"
  printf 'Cache: %s\n' "$last_line"
  printf '\nRun /gitgit:run-spec %s after your fix to record the green result.\n' "$spec_path"

  exit 0
}
