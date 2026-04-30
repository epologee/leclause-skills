---
name: run-spec
user-invocable: true
description: >
  Run a single test/spec file and record the result in the
  gitgit test-runner cache so commit-body.sh can validate
  Tests-trailer paths against actual recent green runs.
argument-hint: "<test-or-spec-path>"
---

# /gitgit:run-spec

Run a single test or spec file through the project's test runner, capture the
exit code, and write the result to the gitgit test-runner cache
(`~/.claude/var/gitgit-test-runs.log` by default, overridable via
`GITGIT_TEST_CACHE`).

The recorded entry allows `commit-body.sh` (when `GITGIT_TEST_CACHE_REQUIRED=1`)
to verify that every path listed in the `Tests:` commit-body trailer has an
actual recent green run before the commit is accepted.

## Usage

```
/gitgit:run-spec <test-or-spec-path>
```

Example:

```
/gitgit:run-spec spec/services/session_spec.rb
/gitgit:run-spec src/__tests__/session.test.ts
/gitgit:run-spec internal/session/session_test.go
/gitgit:run-spec tests/test_session.py
```

## What it does

1. Detects the project's test runner via heuristics (see below).
2. Runs the specified file with the detected runner.
3. Captures the exit code (0 = green, non-zero = red).
4. Records a cache entry: `<timestamp>|<path>|<tree-sha>|<exit-code>`.
5. Prints a `PASS` or `FAIL` summary line, the exit code, and the written
   cache entry.

The skill exits with the test runner's own exit code so callers can use it in
shell pipelines.

## Runner detection heuristics

The implementation in `lib/run-spec.sh` inspects the project root for marker
files in this order:

| Marker file | Runner used |
|-------------|-------------|
| `go.mod` | `go test ./...` (path treated as package pattern) |
| `Gemfile` or `.rspec` | `bundle exec rspec <path>` |
| `package.json` with `"jest"` key | `npx jest <path>` |
| `package.json` with `"vitest"` key | `npx vitest run <path>` |
| `pyproject.toml` or `pytest.ini` or `setup.cfg` | `pytest <path>` |

If multiple markers are present the order above determines priority. When no
marker matches, the skill prints an error asking the operator to set
`GITGIT_TEST_RUNNER` (e.g. `export GITGIT_TEST_RUNNER="bundle exec rspec"`).

## Cache entry

After each run the skill appends one line to the cache file:

```
2026-04-30T12:34:56Z|spec/services/session_spec.rb|<tree-sha>|0
```

- The tree SHA comes from `git write-tree` on the current staged index.  It
  allows `commit-body.sh` to warn when the cache entry was recorded against a
  different staged tree than the one being committed.
- The exit code is `0` for a passing run and non-zero for a failing run.

## Output

```
PASS  spec/services/session_spec.rb  (exit 0)
Cache: 2026-04-30T12:34:56Z|spec/services/session_spec.rb|abc123|0
```

or

```
FAIL  spec/services/session_spec.rb  (exit 1)
Cache: 2026-04-30T12:34:56Z|spec/services/session_spec.rb|abc123|1
```

## Implementation

The implementation lives in `lib/run-spec.sh` and is sourced by this skill.
Runner detection and cache recording are split into testable functions so
the BATS test suite can exercise them without launching a real test run.
