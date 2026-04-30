#!/usr/bin/env bash
# Shared setup, teardown, and fixture helpers for the test-cache BATS suite.
#
# Strategy:
# - Each test gets an isolated temporary directory.
# - GITGIT_TEST_CACHE is pointed to a per-test cache file inside that tmpdir.
# - A git shim in $TMPDIR_TEST/bin intercepts "git write-tree" and returns a
#   stable fake SHA. All other git calls fall through to the real binary.
# - Timestamp helpers allow injecting synthetic timestamps for expiry testing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_LIB="$SCRIPT_DIR/../../hooks/lib/test-cache.sh"
VALIDATE_LIB="$SCRIPT_DIR/../../hooks/lib/validate-body.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST

  # Per-test isolated cache file.
  export GITGIT_TEST_CACHE="$TMPDIR_TEST/test-runs.log"

  # Git shim: intercepts write-tree; delegates everything else.
  local shim_bin="$TMPDIR_TEST/bin"
  mkdir -p "$shim_bin"

  cat > "$shim_bin/git" <<'SHIM'
#!/usr/bin/env bash
REAL_GIT=$(command -v -p git 2>/dev/null || true)

args=("$@")

# Pattern: git write-tree -> return a stable fake SHA.
if [[ "${args[0]}" = "write-tree" ]]; then
  printf '%s\n' "${GIT_SHIM_TREE_SHA:-deadbeefdeadbeefdeadbeefdeadbeef12345678}"
  exit 0
fi

# Pattern: git interpret-trailers --parse
if [[ "${args[0]}" = "interpret-trailers" && "${args[1]}" = "--parse" ]]; then
  printf '%s' "$GIT_SHIM_INTERPRET_TRAILERS_OUTPUT"
  exit 0
fi

# Pattern: git ls-tree
if [[ "${args[0]}" = "ls-tree" ]]; then
  printf '%s' "${GIT_SHIM_LS_TREE_OUTPUT:-spec/services/session_spec.rb}"
  exit 0
fi

# Pattern: git diff --cached
if [[ "${args[0]}" = "diff" && "${args[*]}" =~ "--cached" ]]; then
  printf '%s' "${GIT_SHIM_DIFF_CACHED_OUTPUT:-}"
  exit 0
fi

# Pattern: git log with %H
if [[ "${args[0]}" = "log" && "${args[*]}" =~ "%H" ]]; then
  [[ -n "${GIT_SHIM_LOG_HASHES:-}" ]] && printf '%s\n' "$GIT_SHIM_LOG_HASHES"
  exit 0
fi

# Pattern: git log with %B
if [[ "${args[0]}" = "log" && "${args[*]}" =~ "%B" ]]; then
  printf '%s\n' "${GIT_SHIM_LOG_BODY:-}"
  exit 0
fi

# Pattern: git rev-parse --abbrev-ref HEAD
if [[ "${args[0]}" = "rev-parse" && "${args[1]}" = "--abbrev-ref" ]]; then
  printf '%s\n' "${GIT_SHIM_HEAD_ABBREV:-main}"
  exit 0
fi

# Pattern: git rev-parse --short HEAD
if [[ "${args[0]}" = "rev-parse" && "${args[1]}" = "--short" ]]; then
  printf '%s\n' "${GIT_SHIM_HEAD_SHORT:-abc1234}"
  exit 0
fi

# Pattern: git rev-parse HEAD
if [[ "${args[0]}" = "rev-parse" && "${args[1]}" = "HEAD" ]]; then
  printf 'abc1234def5678\n'
  exit 0
fi

# Fallback to real git.
if [[ -n "$REAL_GIT" ]]; then
  exec "$REAL_GIT" "$@"
fi

printf 'git shim: unhandled: %s\n' "$*" >&2
exit 1
SHIM
  chmod +x "$shim_bin/git"

  export PATH="$shim_bin:$PATH"

  # Default shim values.
  export GIT_SHIM_TREE_SHA="deadbeefdeadbeefdeadbeefdeadbeef12345678"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  export GIT_SHIM_DIFF_CACHED_OUTPUT=""
  export GIT_SHIM_LOG_HASHES=""
  export GIT_SHIM_LOG_BODY=""
  export GIT_SHIM_HEAD_ABBREV="main"
  export GIT_SHIM_HEAD_SHORT="abc1234"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# ---------------------------------------------------------------------------
# source_cache_lib
# Source the test-cache library in the current (test) shell so its functions
# are available without a subshell.
# ---------------------------------------------------------------------------
source_cache_lib() {
  # shellcheck source=../../hooks/lib/test-cache.sh
  source "$CACHE_LIB"
}

# ---------------------------------------------------------------------------
# invoke_cache_fn <function-name> [args...]
# Call a test_cache_* function in a subshell so BATS "run" can capture output
# and status independently.
# ---------------------------------------------------------------------------
invoke_cache_fn() {
  local fn="$1"; shift
  bash -c "source '$CACHE_LIB'; $fn $(printf '%q ' "$@")" 2>&1
}

# ---------------------------------------------------------------------------
# ts_ago <seconds>
# Return a UTC ISO-8601 timestamp that is <seconds> seconds in the past.
# Used to inject synthetic timestamps for expiry tests.
# ---------------------------------------------------------------------------
ts_ago() {
  local secs="$1"
  local epoch
  epoch=$(date +%s 2>/dev/null || python3 -c 'import time; print(int(time.time()))')
  local past=$(( epoch - secs ))
  # macOS: date -u -r <epoch> forces UTC output.
  if date -u -r "$past" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null; then
    return 0
  fi
  # GNU: date -u -d @<epoch>
  if date -u -d "@$past" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null; then
    return 0
  fi
  # python3 fallback: calendar.timegm / gmtime are always UTC.
  python3 -c "
import time, calendar
t = time.gmtime($past)
print(time.strftime('%Y-%m-%dT%H:%M:%SZ', t))
"
}

# ---------------------------------------------------------------------------
# Fixture commit bodies for validate-body integration tests.
# ---------------------------------------------------------------------------

VALID_BODY_CACHE="$(cat <<'TEMPLATE'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in analytics.

Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
TEMPLATE
)"

VALID_TRAILERS_CACHE="$(cat <<'TR'
Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: yes
TR
)"

# write_fixture <name> <content>
write_fixture() {
  local name="$1"
  local content="$2"
  printf '%s' "$content" > "$TMPDIR_TEST/$name"
  printf '%s' "$TMPDIR_TEST/$name"
}

# invoke_validator <file>
invoke_validator() {
  local file="$1"
  bash -c "source '$VALIDATE_LIB'; validate_body '$file'" 2>&1
}
