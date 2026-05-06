#!/usr/bin/env bats
# Pointer fix for commit-subject deny messages: the rotation reminder
# names the absolute path of the SKILL.md so the password lookup is a
# direct Read, not a grep through the plugin cache. The lookup itself
# stays required (the hook does not pre-reveal the password).

load helpers

@test "rotation reminder names absolute path to commit-discipline SKILL.md" {
  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "commit-discipline/SKILL.md" ]] || {
    printf 'expected SKILL.md path in output, got: %s\n' "$output" >&2
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
