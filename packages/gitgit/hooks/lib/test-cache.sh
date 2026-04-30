#!/bin/bash
# packages/gitgit/hooks/lib/test-cache.sh
# Test-runner result cache for gitgit commit-discipline enforcement.
# Sourced as a library by commit-body.sh, run-spec.sh, saw-red.sh, and BATS tests.
# Never executed directly.
#
# Cache format (one line per entry, pipe-delimited):
#   <iso-timestamp>|<spec-path>|<tree-sha>|<exit-code>
#
# Public functions:
#   test_cache_path                                   -> path to cache file
#   test_cache_record_run <spec> <tree-sha> <code> [ts]  -> append entry
#   test_cache_query_run <spec> [max-age-secs]        -> 0 if recent green exists
#   test_cache_query_red <spec> [max-age-secs]        -> 0 if recent red exists
#   test_cache_query_red_then_green <spec> [max-age]  -> 0 if red before green
#   test_cache_clear [pattern]                        -> empty / prune cache
#   test_cache_tree_sha                               -> git write-tree sha

# ---------------------------------------------------------------------------
# test_cache_path
# ---------------------------------------------------------------------------

# test_cache_path
# Echoes the path to the cache file.
# Override via GITGIT_TEST_CACHE env var; default ~/.claude/var/gitgit-test-runs.log
test_cache_path() {
  printf '%s' "${GITGIT_TEST_CACHE:-$HOME/.claude/var/gitgit-test-runs.log}"
}

# ---------------------------------------------------------------------------
# test_cache_record_run
# ---------------------------------------------------------------------------

# test_cache_record_run <spec_path> <tree_sha> <exit_code> [timestamp]
# Appends one entry to the cache file. Creates parent directory if absent.
# timestamp defaults to the current UTC ISO-8601 time.
test_cache_record_run() {
  local spec_path="$1"
  local tree_sha="$2"
  local exit_code="$3"
  local ts="${4:-$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")}"

  local cache_file
  cache_file=$(test_cache_path)

  mkdir -p "$(dirname "$cache_file")"

  printf '%s|%s|%s|%s\n' "$ts" "$spec_path" "$tree_sha" "$exit_code" >> "$cache_file"
}

# ---------------------------------------------------------------------------
# _tc_now_epoch
# Emit current Unix epoch (seconds). POSIX date does not guarantee %s, but it
# works on macOS and Linux. The fallback path uses python3 for strict POSIX.
# ---------------------------------------------------------------------------

_tc_now_epoch() {
  local ep
  ep=$(date +%s 2>/dev/null)
  if [[ "$ep" =~ ^[0-9]+$ ]]; then
    printf '%s' "$ep"
    return 0
  fi
  # Fallback: python3
  python3 -c 'import time; print(int(time.time()))' 2>/dev/null || printf '0'
}

# ---------------------------------------------------------------------------
# _tc_iso_to_epoch
# Convert an ISO-8601 UTC timestamp (2026-04-30T12:34:56Z) to epoch seconds.
# Uses date -d on Linux, date -j -f on macOS, python3 as fallback.
# ---------------------------------------------------------------------------

_tc_iso_to_epoch() {
  local ts="$1"
  # Strip trailing Z to get a bare datetime string for parsers that need it.
  local ts_bare="${ts%Z}"

  # macOS date -j -u -f: strip Z, force UTC interpretation.
  if date -j -u -f "%Y-%m-%dT%H:%M:%S" "$ts_bare" +%s 2>/dev/null; then
    return 0
  fi

  # GNU date -d with explicit UTC suffix.
  if date -d "${ts_bare} UTC" +%s 2>/dev/null; then
    return 0
  fi

  # python3 fallback: calendar.timegm interprets struct_time as UTC.
  python3 -c "
import time, calendar
ts = '$ts_bare'
try:
    t = time.strptime(ts, '%Y-%m-%dT%H:%M:%S')
    print(int(calendar.timegm(t)))
except Exception:
    print(0)
" 2>/dev/null || printf '0'
}

# ---------------------------------------------------------------------------
# test_cache_query_run
# ---------------------------------------------------------------------------

# test_cache_query_run <spec_path> [max_age_seconds=600]
# Returns 0 (and echoes matched line) if there is a recent green run for the
# given spec path whose timestamp is within max_age_seconds of now.
# Returns 1 otherwise.
test_cache_query_run() {
  local spec_path="$1"
  local max_age="${2:-600}"

  local cache_file
  cache_file=$(test_cache_path)
  [[ ! -f "$cache_file" ]] && return 1

  local now_epoch
  now_epoch=$(_tc_now_epoch)

  local matched_line=""
  local matched_age=999999999

  while IFS='|' read -r ts path tree_sha code; do
    # Skip malformed lines.
    [[ -z "$ts" || -z "$path" || -z "$code" ]] && continue
    # Match spec path.
    [[ "$path" != "$spec_path" ]] && continue
    # Must be green (exit 0).
    [[ "$code" != "0" ]] && continue

    local entry_epoch
    entry_epoch=$(_tc_iso_to_epoch "$ts")
    local age=$(( now_epoch - entry_epoch ))

    # Age must be within window.
    [[ "$age" -gt "$max_age" ]] && continue

    # Track the most recent match (smallest non-negative age).
    if [[ "$age" -lt "$matched_age" ]]; then
      matched_age=$age
      matched_line="$ts|$path|$tree_sha|$code"
    fi
  done < "$cache_file"

  if [[ -n "$matched_line" ]]; then
    printf '%s\n' "$matched_line"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# test_cache_query_red
# ---------------------------------------------------------------------------

# test_cache_query_red <spec_path> [max_age_seconds=600]
# Returns 0 (and echoes matched line) if there is a recent red (exit_code != 0)
# run for spec_path within max_age_seconds.
test_cache_query_red() {
  local spec_path="$1"
  local max_age="${2:-600}"

  local cache_file
  cache_file=$(test_cache_path)
  [[ ! -f "$cache_file" ]] && return 1

  local now_epoch
  now_epoch=$(_tc_now_epoch)

  local matched_line=""
  local matched_age=999999999

  while IFS='|' read -r ts path tree_sha code; do
    [[ -z "$ts" || -z "$path" || -z "$code" ]] && continue
    [[ "$path" != "$spec_path" ]] && continue
    # Must be red (exit code non-zero).
    [[ "$code" = "0" ]] && continue

    local entry_epoch
    entry_epoch=$(_tc_iso_to_epoch "$ts")
    local age=$(( now_epoch - entry_epoch ))
    [[ "$age" -gt "$max_age" ]] && continue

    if [[ "$age" -lt "$matched_age" ]]; then
      matched_age=$age
      matched_line="$ts|$path|$tree_sha|$code"
    fi
  done < "$cache_file"

  if [[ -n "$matched_line" ]]; then
    printf '%s\n' "$matched_line"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# test_cache_query_red_then_green
# ---------------------------------------------------------------------------

# test_cache_query_red_then_green <spec_path> [max_age_seconds=600]
# Returns 0 if within the time window there exists:
#   - at least one RED entry for spec_path, AND
#   - at least one GREEN entry for spec_path whose timestamp is AFTER the
#     earliest RED entry within the window.
# Order matters: the red must precede the green chronologically.
# Returns 1 otherwise.
test_cache_query_red_then_green() {
  local spec_path="$1"
  local max_age="${2:-600}"

  local cache_file
  cache_file=$(test_cache_path)
  [[ ! -f "$cache_file" ]] && return 1

  local now_epoch
  now_epoch=$(_tc_now_epoch)

  local earliest_red_epoch=""
  local latest_green_epoch=""

  while IFS='|' read -r ts path tree_sha code; do
    [[ -z "$ts" || -z "$path" || -z "$code" ]] && continue
    [[ "$path" != "$spec_path" ]] && continue

    local entry_epoch
    entry_epoch=$(_tc_iso_to_epoch "$ts")
    local age=$(( now_epoch - entry_epoch ))
    [[ "$age" -gt "$max_age" ]] && continue

    if [[ "$code" != "0" ]]; then
      # Red entry.
      if [[ -z "$earliest_red_epoch" ]] || [[ "$entry_epoch" -lt "$earliest_red_epoch" ]]; then
        earliest_red_epoch="$entry_epoch"
      fi
    else
      # Green entry.
      if [[ -z "$latest_green_epoch" ]] || [[ "$entry_epoch" -gt "$latest_green_epoch" ]]; then
        latest_green_epoch="$entry_epoch"
      fi
    fi
  done < "$cache_file"

  # Both must exist, and green must be strictly after the earliest red.
  if [[ -n "$earliest_red_epoch" && -n "$latest_green_epoch" ]]; then
    if [[ "$latest_green_epoch" -gt "$earliest_red_epoch" ]]; then
      return 0
    fi
  fi
  return 1
}

# ---------------------------------------------------------------------------
# test_cache_clear
# ---------------------------------------------------------------------------

# test_cache_clear [pattern]
# When no pattern is given: truncates the cache file entirely.
# When pattern is given: removes lines containing that literal pattern.
test_cache_clear() {
  local pattern="${1:-}"
  local cache_file
  cache_file=$(test_cache_path)

  if [[ ! -f "$cache_file" ]]; then
    return 0
  fi

  if [[ -z "$pattern" ]]; then
    : > "$cache_file"
  else
    local tmp
    tmp=$(mktemp /tmp/gitgit-tc-XXXXXX)
    grep -vF "$pattern" "$cache_file" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$cache_file"
  fi
}

# ---------------------------------------------------------------------------
# test_cache_tree_sha
# ---------------------------------------------------------------------------

# test_cache_tree_sha
# Echoes the tree SHA of the current staged index (git write-tree).
# Returns empty string on failure (e.g. outside a git repo).
test_cache_tree_sha() {
  git write-tree 2>/dev/null || printf ''
}
