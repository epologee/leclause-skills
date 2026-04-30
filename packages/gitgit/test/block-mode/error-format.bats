#!/usr/bin/env bats
# error-format.bats
# The deny error message names the exact missing trailer and includes both
# a synthesized example and the opt-out enum for each violation type.

load helpers

# ---------------------------------------------------------------------------
# Helper: build a commit body with a WHY block but missing specific trailers.
# ---------------------------------------------------------------------------

# valid_why_only_cmd <subject>
# A heredoc commit with a WHY paragraph but NO trailers at all.
valid_why_only_cmd() {
  local subject="$1"
  local cmd
  cmd=$(commit_cmd_heredoc \
    "$subject" \
    "$(printf 'This change addresses a latent race condition in the session\nhandler that manifested under high concurrency in staging.')")
  printf '%s # ack-rule4' "$cmd"
}

# commit_with_trailers_cmd <subject> <trailer-block>
# A heredoc commit with WHY + given trailers.
commit_with_trailers_cmd() {
  local subject="$1"
  local trailers="$2"
  local cmd
  cmd=$(commit_cmd_heredoc \
    "$subject" \
    "$(printf 'This change addresses a latent race condition in the session\nhandler that manifested under high concurrency in staging.\n\n%s' "$trailers")")
  printf '%s # ack-rule4' "$cmd"
}

# ---------------------------------------------------------------------------
# missing-tests
# ---------------------------------------------------------------------------

@test "missing-tests violation: error names Tests as the missing key" {
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 25 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/session.rb\napp/services/session_service.rb\nspec/models/session_spec.rb')"
  # Trailers have Slice and Red-then-green but no Tests.
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Slice: handler + spec\nRed-then-green: yes')"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "Session boundary model for meter events" \
    "$(printf 'Slice: handler + spec\nRed-then-green: yes')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-tests"* ]]
}

@test "missing-tests violation: error includes synthesized spec-path in example" {
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 25 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/session.rb\napp/services/session_service.rb\nspec/models/session_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Slice: handler + spec\nRed-then-green: yes')"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "Session boundary model for meter events" \
    "$(printf 'Slice: handler + spec\nRed-then-green: yes')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  # The synthesized example should contain the spec path from staged diff.
  [[ "$output" == *"session_spec.rb"* ]]
}

@test "missing-tests violation: error includes opt-out enum" {
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 25 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/session.rb\napp/services/session_service.rb\nspec/models/session_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Slice: handler + spec\nRed-then-green: yes')"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "Session boundary model for meter events" \
    "$(printf 'Slice: handler + spec\nRed-then-green: yes')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"config-only"* ]]
  [[ "$output" == *"migration-only"* ]]
}

# ---------------------------------------------------------------------------
# missing-slice
# ---------------------------------------------------------------------------

@test "missing-slice violation: error names Slice as the missing key" {
  export GIT_SHIM_SHORTSTAT=" 2 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/user.rb\nspec/models/user_spec.rb')"
  # Trailers present but no Slice.
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Tests: spec/models/user_spec.rb\nRed-then-green: yes')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/models/user_spec.rb"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "User validation rule for enrollment" \
    "$(printf 'Tests: spec/models/user_spec.rb\nRed-then-green: yes')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-slice"* ]]
}

@test "missing-slice violation: error includes opt-out enum" {
  export GIT_SHIM_SHORTSTAT=" 2 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/user.rb\nspec/models/user_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Tests: spec/models/user_spec.rb\nRed-then-green: yes')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/models/user_spec.rb"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "User validation rule for enrollment" \
    "$(printf 'Tests: spec/models/user_spec.rb\nRed-then-green: yes')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"wip"* ]]
  [[ "$output" == *"chore-deps"* ]]
}

# ---------------------------------------------------------------------------
# missing-red-then-green
# ---------------------------------------------------------------------------

@test "missing-red-then-green violation: error names Red-then-green as missing key" {
  export GIT_SHIM_SHORTSTAT=" 2 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/controllers/orders.rb\nspec/controllers/orders_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Tests: spec/controllers/orders_spec.rb\nSlice: handler + spec')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/controllers/orders_spec.rb"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "Order creation handler for checkout flow" \
    "$(printf 'Tests: spec/controllers/orders_spec.rb\nSlice: handler + spec')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-red-then-green"* ]]
}

@test "missing-red-then-green violation: error includes opt-out enum" {
  export GIT_SHIM_SHORTSTAT=" 2 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/controllers/orders.rb\nspec/controllers/orders_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf 'Tests: spec/controllers/orders_spec.rb\nSlice: handler + spec')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/controllers/orders_spec.rb"

  local cmd
  cmd=$(commit_with_trailers_cmd \
    "Order creation handler for checkout flow" \
    "$(printf 'Tests: spec/controllers/orders_spec.rb\nSlice: handler + spec')")

  run_dispatch "$cmd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"docs-only"* ]]
  [[ "$output" == *"revert"* ]]
}
