#!/usr/bin/env bats
# repo-detect.bats
# Verify that the commit-body shadow guard activates only for the
# leclause-skills repo and stays silent for all other repos.

load helpers

# ---------------------------------------------------------------------------
# leclause-skills URL: guard fires on a violation
# ---------------------------------------------------------------------------

@test "leclause-skills repo URL activates guard: warn observed on missing body" {
  export GIT_SHIM_ORIGIN_URL="git@github.com:epologee/leclause-skills.git"
  # Non-trivial diff so trivial shortcut does not apply.
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb\nd.rb\ne.rb')"
  # No trailers -> validate_body will emit missing-body for a single-line commit.
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  # Ack the rotation rule so commit-subject guard does not interfere.
  run_dispatch 'git commit -m "Expose session endpoint" # ack-rule4'

  # dispatch exits 0 (warn mode, never denies).
  [ "$status" -eq 0 ]
  # stdout must carry an additionalContext JSON with our mnemonic.
  [[ "$output" == *'"additionalContext"'* ]]
  [[ "$output" == *'commit-body-shadow'* ]]
}

@test "leclause-skills HTTPS URL also activates guard" {
  export GIT_SHIM_ORIGIN_URL="https://github.com/epologee/leclause-skills.git"
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 15 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'x.rb\ny.rb\nz.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  run_dispatch 'git commit -m "Expose unused import path" # ack-rule4'

  [ "$status" -eq 0 ]
  [[ "$output" == *'commit-body-shadow'* ]]
}

# ---------------------------------------------------------------------------
# Other-repo URL: guard is completely silent
# ---------------------------------------------------------------------------

@test "other-repo URL skips silently: no warn, no log entry" {
  export GIT_SHIM_ORIGIN_URL="https://github.com/someorg/otherrepo.git"
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb\nd.rb\ne.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  local before
  before=$(shadow_log_line_count)

  run_dispatch 'git commit -m "Expose session endpoint" # ack-rule4'

  # No deny.
  [ "$status" -eq 0 ]
  # No commit-body-shadow context in output.
  [[ "$output" != *'commit-body-shadow'* ]]
  # No new shadow log entry.
  local after
  after=$(shadow_log_line_count)
  [ "$after" -eq "$before" ]
}

@test "empty remote URL skips silently" {
  export GIT_SHIM_ORIGIN_URL=""
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb')"

  local before
  before=$(shadow_log_line_count)

  run_dispatch 'git commit -m "Expose session endpoint" # ack-rule4'

  [ "$status" -eq 0 ]
  [[ "$output" != *'commit-body-shadow'* ]]
  local after
  after=$(shadow_log_line_count)
  [ "$after" -eq "$before" ]
}
