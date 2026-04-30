#!/usr/bin/env bats
# Slice trailer presence / absence and opt-out enum acceptance.

load helpers

# ---------------------------------------------------------------------------
# Slice trailer present / absent / empty (4 cases)
# ---------------------------------------------------------------------------

@test "commit without Slice trailer fails with missing-slice" {
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Red-then-green: yes"
  local body
  body="$(cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event.

Tests: spec/services/session_spec.rb
Red-then-green: yes
MSG
)"
  local file
  file=$(write_fixture "no-slice.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-slice"* ]]
}

@test "commit with empty Slice value fails with missing-slice" {
  # Shim returns Slice: with empty value (trailing space stripped by grep).
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Red-then-green: yes"
  local body
  body="$(cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation.

Tests: spec/services/session_spec.rb
Red-then-green: yes
MSG
)"
  local file
  file=$(write_fixture "empty-slice.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-slice"* ]]
}

@test "commit with valid free-text Slice passes" {
  use_trailers "$VALID_TRAILERS"
  local file
  file=$(write_fixture "valid-slice.txt" "$VALID_BODY_TEMPLATE")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "commit with Slice opt-out token docs-only skips Tests and RTG checks" {
  use_trailers "Slice: docs-only"
  local body
  body="$(cat <<'MSG'
Update CONTRIBUTING guide with commit schema

The new body schema requires three trailers; this commit documents
the format, the opt-out tokens, and the escape hatch.

Slice: docs-only
MSG
)"
  local file
  file=$(write_fixture "docs-only.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Opt-out enum tokens (4 cases covering all 7 tokens)
# ---------------------------------------------------------------------------

@test "Slice: config-only is accepted without Tests or RTG" {
  use_trailers "Slice: config-only"
  local body
  body="$(cat <<'MSG'
Tighten rubocop line-length to 100

The default 120-char limit lets wide lines slip through code review.
Narrowing to 100 aligns with the existing editor ruler setting.

Slice: config-only
MSG
)"
  local file
  file=$(write_fixture "config-only.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Slice: migration-only exempts Tests but still requires Red-then-green" {
  # migration-only is in the opt-out set (Tests exempt) but NOT in RTG-exempt.
  use_trailers "Slice: migration-only"
  local body
  body="$(cat <<'MSG'
Add null constraint to sessions.user_id

The column was added without a NOT NULL in the original migration.
Backfilling confirmed no null rows exist in production.

Slice: migration-only
MSG
)"
  local file
  file=$(write_fixture "migration-only.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-red-then-green"* ]]
}

@test "Slice: chore-deps is accepted without Tests and RTG" {
  use_trailers "Slice: chore-deps"
  local body
  body="$(cat <<'MSG'
Bump bundler to 2.5.18

Security advisory CVE-2025-9999 affects bundler < 2.5.18.
Upgrading resolves the advisory without behaviour change.

Slice: chore-deps
MSG
)"
  local file
  file=$(write_fixture "chore-deps.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Slice: wip is accepted without Tests but still requires RTG" {
  # wip is in opt-out (no Tests) but NOT in RTG-exempt (RTG still required).
  use_trailers "Slice: wip"$'\n'"Red-then-green: n/a (work in progress, tests come next)"
  local body
  body="$(cat <<'MSG'
Wire session boundary to analytics pipeline (WIP)

First pass connecting the event bus to the analytics ingestion layer.
This commit intentionally skips the adapter layer; next commit adds it.

Slice: wip
Red-then-green: n/a (work in progress, tests come next)
MSG
)"
  local file
  file=$(write_fixture "wip.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}
