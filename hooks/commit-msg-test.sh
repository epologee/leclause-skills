#!/bin/sh
set -e

HOOK="hooks/commit-msg"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

run_hook() {
  printf '%s\n' "$1" > "$TMP"
  "$HOOK" "$TMP" >/dev/null 2>&1
}

body_without_trailer="Subject

Body without the marker."
if run_hook "$body_without_trailer"; then
  fail "missing-trailer should be denied"
fi
pass "missing-trailer denied"

body_with_pii_doublecheck="Subject

Body with trailer.

PII-Doublecheck: yes"
if ! run_hook "$body_with_pii_doublecheck"; then
  fail "valid trailer should be accepted"
fi
pass "valid trailer accepted"

body_with_legacy_bracket_marker="Subject

Body with the old marker.

[doublecheck]"
if run_hook "$body_with_legacy_bracket_marker"; then
  fail "bracket marker should be rejected after migration"
fi
pass "bracket marker rejected"

echo ""
echo "All assertions passed."
