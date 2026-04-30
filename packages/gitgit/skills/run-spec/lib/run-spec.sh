#!/bin/bash
# packages/gitgit/skills/run-spec/lib/run-spec.sh
# Runner detection, execution, and cache recording for /gitgit:run-spec.
# Sourced by the SKILL.md execution context and by BATS tests.
# Never executed directly; the caller is responsible for set -euo pipefail.
#
# Public functions:
#   run_spec_detect_runner <project-root>  -> echoes runner command prefix
#   run_spec_run <spec-path> [project-root] -> runs test, records cache, exits
#                                              with test runner exit code

# Locate the hooks/lib directory relative to this file so test-cache.sh can
# be sourced regardless of CWD.
_RS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
_RS_HOOKS_LIB="$_RS_LIB_DIR/../../../hooks/lib/test-cache.sh"

if [[ -f "$_RS_HOOKS_LIB" ]]; then
  # shellcheck source=../../../hooks/lib/test-cache.sh
  source "$_RS_HOOKS_LIB"
fi

# ---------------------------------------------------------------------------
# run_spec_detect_runner <project-root>
# Echoes the runner command prefix (e.g. "bundle exec rspec").
# Returns 1 if no runner could be detected.
# ---------------------------------------------------------------------------
run_spec_detect_runner() {
  local root="${1:-.}"

  # Allow explicit override.
  if [[ -n "${GITGIT_TEST_RUNNER:-}" ]]; then
    printf '%s' "$GITGIT_TEST_RUNNER"
    return 0
  fi

  # Go: go.mod present.
  if [[ -f "$root/go.mod" ]]; then
    printf 'go test'
    return 0
  fi

  # Ruby: Gemfile or .rspec.
  if [[ -f "$root/Gemfile" || -f "$root/.rspec" ]]; then
    if command -v bundle >/dev/null 2>&1; then
      printf 'bundle exec rspec'
    else
      printf 'rspec'
    fi
    return 0
  fi

  # Node: package.json with jest or vitest.
  if [[ -f "$root/package.json" ]]; then
    if grep -q '"jest"' "$root/package.json" 2>/dev/null; then
      printf 'npx jest'
      return 0
    fi
    if grep -q '"vitest"' "$root/package.json" 2>/dev/null; then
      printf 'npx vitest run'
      return 0
    fi
  fi

  # Python: pyproject.toml, pytest.ini, or setup.cfg with [tool:pytest].
  if [[ -f "$root/pyproject.toml" || -f "$root/pytest.ini" || -f "$root/setup.cfg" ]]; then
    printf 'pytest'
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# run_spec_run <spec-path> [project-root]
# Detects runner, runs the spec, records the cache entry, prints summary.
# Exits with the test runner's exit code.
# ---------------------------------------------------------------------------
run_spec_run() {
  local spec_path="$1"
  local project_root="${2:-.}"

  if [[ -z "$spec_path" ]]; then
    printf 'run-spec: spec path argument is required\n' >&2
    exit 1
  fi

  local runner
  if ! runner=$(run_spec_detect_runner "$project_root"); then
    printf 'run-spec: could not detect test runner.\n' >&2
    printf 'Set GITGIT_TEST_RUNNER to the runner command (e.g. "bundle exec rspec").\n' >&2
    exit 1
  fi

  # Capture the staged tree SHA before running (so cache reflects the index
  # state at run time, not after any edits that happen post-run).
  local tree_sha=""
  if command -v test_cache_tree_sha >/dev/null 2>&1; then
    tree_sha=$(test_cache_tree_sha 2>/dev/null || printf '')
  fi
  [[ -z "$tree_sha" ]] && tree_sha=$(git write-tree 2>/dev/null || printf 'unknown')

  # Run the test.
  local test_exit=0
  $runner "$spec_path"
  test_exit=$?

  # Record in cache.
  if command -v test_cache_record_run >/dev/null 2>&1; then
    test_cache_record_run "$spec_path" "$tree_sha" "$test_exit"
    local cache_entry
    cache_entry=$(test_cache_path)
    local last_line
    last_line=$(tail -1 "$cache_entry" 2>/dev/null || printf '')
    if [[ "$test_exit" -eq 0 ]]; then
      printf 'PASS  %s  (exit 0)\n' "$spec_path"
    else
      printf 'FAIL  %s  (exit %s)\n' "$spec_path" "$test_exit"
    fi
    printf 'Cache: %s\n' "$last_line"
  else
    # test-cache.sh not available; still report result.
    if [[ "$test_exit" -eq 0 ]]; then
      printf 'PASS  %s  (exit 0)\n' "$spec_path"
    else
      printf 'FAIL  %s  (exit %s)\n' "$spec_path" "$test_exit"
    fi
    printf 'Cache: unavailable (test-cache.sh not loaded)\n'
  fi

  exit "$test_exit"
}
