#!/usr/bin/env bats
# parser-equivalence.bats
# Verifies that PreToolUse string parsing and direct file-input parsing
# produce equivalent validate_body verdicts for the same commit message
# expressed in multiple syntactic forms.
#
# For each form the test:
#   1. Extracts the message via dd_extract_commit_message (same as commit-body.sh).
#   2. Writes it to a temp file and calls validate_body directly.
# Both paths must produce the same exit code and the same leading violation
# code (or both succeed with exit 0).

load helpers

# Standard valid commit body used across all equivalence tests.
# Trailers are shimmed via GIT_SHIM_INTERPRET_TRAILERS_OUTPUT.
_setup_valid_shim() {
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf \
    'Tests: spec/services/session_spec.rb\nSlice: handler + service + spec\nRed-then-green: yes')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
}

# invoke_via_extract <bash-command>
# Runs dd_extract_commit_message on the command, writes to a file, calls
# validate_body, and returns the exit code via stdout as the last token.
invoke_via_extract() {
  local cmd="$1"
  bash -c "
    source '$VALIDATOR'
    msg=\$(source '$(dirname "$VALIDATOR")/../lib/common.sh' 2>/dev/null; \
           dd_extract_commit_message '$cmd' 2>/dev/null || true)
    if [[ -z \"\$msg\" ]]; then
      printf 'empty-extract\n'
      exit 2
    fi
    tmpf=\$(mktemp)
    printf '%s' \"\$msg\" > \"\$tmpf\"
    validate_body \"\$tmpf\" 2>&1
    rc=\$?
    rm -f \"\$tmpf\"
    exit \$rc
  " 2>&1
}

# Standard valid message text (used in fixture building below).
_VALID_SUBJECT="Expose session boundary on transaction events"
_VALID_WHY="$(printf 'When StartTransaction messages arrive with an invalid meter\nreading we previously rejected the entire event.')"
_VALID_TRAILERS="$(printf 'Tests: spec/services/session_spec.rb\nSlice: handler + service + spec\nRed-then-green: yes')"

# ---------------------------------------------------------------------------
# Form 1: simple -m "subject only" (trivial flag set to pass)
# ---------------------------------------------------------------------------

@test "equivalence: single-line -m form matches file-input verdict (trivial OK)" {
  _setup_valid_shim
  export GITGIT_TRIVIAL_OK=1

  local cmd
  cmd="git commit -m \"${_VALID_SUBJECT}\""

  # File-input path.
  local file
  file=$(write_fixture "form1.txt" "${_VALID_SUBJECT}")
  run invoke_validator_file "$file"
  local file_status=$status

  # Extract path.
  local extract_out extract_status
  extract_out=$(invoke_via_extract "$cmd")
  extract_status=$?

  [ "$file_status" -eq "$extract_status" ]
}

# ---------------------------------------------------------------------------
# Form 2: heredoc <<'EOF' (standard Claude Code multi-line form)
# ---------------------------------------------------------------------------

@test "equivalence: heredoc EOF form matches file-input verdict" {
  _setup_valid_shim

  local body
  body="${_VALID_SUBJECT}"$'\n\n'"${_VALID_WHY}"$'\n\n'"${_VALID_TRAILERS}"

  local cmd
  cmd="git commit -m \"\$(cat <<'EOF'
${body}
EOF
)\""

  # File-input path.
  local file
  file=$(write_fixture "form2.txt" "$body")
  run invoke_validator_file "$file"
  local file_status=$status

  # Extract path: dd_extract_commit_message handles heredoc.
  local extract_out extract_status
  extract_out=$(invoke_via_extract "$cmd")
  extract_status=$?

  [ "$file_status" -eq "$extract_status" ]
}

# ---------------------------------------------------------------------------
# Form 3: missing body (invalid) - both paths must agree on violation
# ---------------------------------------------------------------------------

@test "equivalence: missing-body verdict is consistent between paths" {
  _setup_valid_shim
  export GITGIT_TRIVIAL_OK=0

  local subject="Subject without body"
  local cmd="git commit -m \"${subject}\""

  # File-input path.
  local file
  file=$(write_fixture "form3.txt" "$subject")
  run invoke_validator_file "$file"
  local file_status=$status
  local file_code
  file_code=$(printf '%s' "$output" | head -1 | cut -d: -f1)

  # Extract path.
  local extract_out extract_status
  extract_out=$(invoke_via_extract "$cmd")
  extract_status=$?
  local extract_code
  extract_code=$(printf '%s' "$extract_out" | head -1 | cut -d: -f1)

  [ "$file_status" -eq "$extract_status" ]
  [ "$file_code" = "$extract_code" ]
}

# ---------------------------------------------------------------------------
# Form 4: body with embedded $ and quotes
# ---------------------------------------------------------------------------

@test "equivalence: body with dollar signs and quotes matches file-input verdict" {
  _setup_valid_shim

  # Use a body whose content has literal $ (safe in the written fixture).
  local body
  body="$(printf '%s\n\n%s\n\n%s' \
    "Expose session boundary on transaction events" \
    "The variable \$session_id must not be nil at ingestion time.
This guards against a nil-deref that only appeared under load." \
    "${_VALID_TRAILERS}")"

  # File-input path.
  local file
  file=$(write_fixture "form4.txt" "$body")
  run invoke_validator_file "$file"
  local file_status=$status

  # Heredoc form keeps $ literal in the payload.
  local cmd
  cmd="git commit -m \"\$(cat <<'GITEOF'
${body}
GITEOF
)\""

  local extract_out extract_status
  extract_out=$(invoke_via_extract "$cmd")
  extract_status=$?

  [ "$file_status" -eq "$extract_status" ]
}

# ---------------------------------------------------------------------------
# Form 5: missing-slice violation - both paths must agree
# ---------------------------------------------------------------------------

@test "equivalence: missing-slice verdict is consistent between paths" {
  # Shim returns no Slice trailer.
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$(printf \
    'Tests: spec/services/session_spec.rb\nRed-then-green: yes')"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  export GITGIT_TRIVIAL_OK=0

  local body
  body="$(printf '%s\n\n%s\n\n%s' \
    "Expose session boundary on transaction events" \
    "When StartTransaction messages arrive with an invalid meter
reading we previously rejected the entire event." \
    "$(printf 'Tests: spec/services/session_spec.rb\nRed-then-green: yes')")"

  # File-input path.
  local file
  file=$(write_fixture "form5.txt" "$body")
  run invoke_validator_file "$file"
  local file_status=$status
  local file_code
  file_code=$(printf '%s' "$output" | head -1 | cut -d: -f1)

  # Extract path via heredoc.
  local cmd
  cmd="git commit -m \"\$(cat <<'EOF'
${body}
EOF
)\""
  local extract_out extract_status
  extract_out=$(invoke_via_extract "$cmd")
  extract_status=$?
  local extract_code
  extract_code=$(printf '%s' "$extract_out" | head -1 | cut -d: -f1)

  [ "$file_status" -eq "$extract_status" ]
  [ "$file_code" = "$extract_code" ]
}
