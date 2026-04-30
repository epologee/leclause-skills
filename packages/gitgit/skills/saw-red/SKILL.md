---
name: saw-red
user-invocable: true
description: >
  Manually log that you observed a test/spec in red state.
  Use when running the test outside /gitgit:run-spec but you
  still want commit-body.sh's Red-then-green: yes validation
  to pass.
argument-hint: "<test-or-spec-path>"
---

# /gitgit:saw-red

Writes a RED entry (exit code 1) for the given spec path to the gitgit
test-runner cache (`~/.claude/var/gitgit-test-runs.log` by default, override
via `GITGIT_TEST_CACHE`).

## When to use this

Use `/gitgit:saw-red` when you ran a test manually (in a terminal, via your
IDE, or via CI) and observed it failing, but you did not use `/gitgit:run-spec`
to run it. Without a RED cache entry, `commit-body.sh`'s
`Red-then-green: yes` validation will reject your commit with:

```
red-then-green-evidence-missing: <path> has no recent red preceding green
```

This skill records the observation so the subsequent green run (via
`/gitgit:run-spec`) can satisfy the `red-then-green` check.

## Usage

```
/gitgit:saw-red <test-or-spec-path>
```

Example:

```
/gitgit:saw-red spec/services/session_spec.rb
/gitgit:saw-red src/__tests__/session.test.ts
```

## What it does

1. Captures the current staged tree SHA via `git write-tree`.
2. Appends a RED entry (exit code 1) to the cache:
   `<timestamp>|<path>|<tree-sha>|1`
3. Prints a confirmation line.

After recording the red observation, make your fix, then run
`/gitgit:run-spec <path>` to record the green result. The combination
satisfies `Red-then-green: yes` validation.

## Implementation

The implementation lives in `lib/saw-red.sh`.
