#!/usr/bin/env bats
# Pointer fix for commit-subject deny messages: the rotation reminder
# names the absolute path of the SKILL.md so the password lookup is a
# direct Read, not a grep through the plugin cache. The lookup itself
# stays required (the hook does not pre-reveal the password).
# Broken installs surface loudly rather than silently degrading to the
# slash-command form (which would re-introduce grep-fishing).

load helpers

@test "rotation reminder names absolute path to commit-discipline SKILL.md" {
  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]
  # Capture the absolute path the hook emitted: anything from the first
  # leading "/" up to "/SKILL.md".
  local extracted
  extracted=$(printf '%s' "$output" | grep -oE '/[A-Za-z0-9_./ -]*/SKILL\.md' | head -1)
  [[ -n "$extracted" ]] || {
    printf 'expected absolute SKILL.md path in output, got: %s\n' "$output" >&2
    return 1
  }
  [[ "$extracted" == /* ]] || {
    printf 'expected path to be absolute, got: %s\n' "$extracted" >&2
    return 1
  }
  [ -f "$extracted" ] || {
    printf 'expected SKILL.md to exist on disk at: %s\n' "$extracted" >&2
    return 1
  }
  [[ "$output" =~ "Rotation reminders" ]] || {
    printf 'expected section anchor in output, got: %s\n' "$output" >&2
    return 1
  }
}

@test "deny still tells the operator to paste the ack token" {
  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "ack-rule" ]] || {
    printf 'expected ack-rule instruction in output, got: %s\n' "$output" >&2
    return 1
  }
}

@test "broken install surfaces a loud deny instead of silently degrading" {
  # Force the skill-path resolution to fail by pointing _DD_HERE at a
  # nonexistent location for this dispatch run. With no slash-command
  # fallback any more, the hook must emit the install-broken deny.
  local broken_root="$BATS_TEST_TMPDIR/no-such-install"
  mkdir -p "$broken_root/hooks/guards"
  cp packages/gitgit/hooks/guards/commit-subject.sh "$broken_root/hooks/guards/"
  cp packages/gitgit/hooks/lib/rotation-rules.sh "$broken_root/hooks/guards/"
  # Run the guard in isolation: source common.sh from the real install
  # (so dd_extract_commit_message and dd_emit_deny exist), then source
  # the relocated commit-subject.sh which sets _DD_HERE to the broken
  # path.
  run bash -c "
    source packages/gitgit/hooks/lib/common.sh
    DD_RULE_PASSWORD=()
    source packages/gitgit/hooks/lib/rotation-rules.sh
    _DD_HERE='$broken_root/hooks/guards'
    source '$broken_root/hooks/guards/commit-subject.sh'
    json='{\"tool_input\":{\"command\":\"git commit -m \\\"Some subject\\\"\"}}'
    guard_commit_subject \"\$json\"
  "
  [ "$status" -eq 2 ]
  [[ "$output" =~ "install appears broken" ]] || {
    printf 'expected install-broken deny in output, got: %s\n' "$output" >&2
    return 1
  }
  [[ "$output" =~ "Reinstall gitgit@leclause" ]] || {
    printf 'expected reinstall instruction in output, got: %s\n' "$output" >&2
    return 1
  }
}
