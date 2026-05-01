---
name: run-spec
user-invocable: true
description: >
  Detect the project's test runner and run a single spec/test file.
  Echoes PASS or FAIL plus the runner output. Useful as an ergonomic
  helper for /gitgit:commit-discipline workflows.
argument-hint: "<test-or-spec-path>"
---

# /gitgit:run-spec

Detects the project's test runner and runs a single test or spec file.
Prints a `PASS` or `FAIL` summary line plus the runner's own output.
The skill exits with the test runner's exit code so callers can use it
in shell pipelines.

This skill does not record evidence anywhere. `Red-then-green: yes` in
the commit body is self-attestation; no cache lookup backs it.

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
4. Prints a `PASS` or `FAIL` summary line and the exit code.

## Runner detection heuristics

The implementation in `lib/run-spec.sh` inspects the project root for marker
files in this order:

| Marker file | Runner used |
|-------------|-------------|
| `go.mod` | `go test` |
| `Gemfile` or `.rspec` | `bundle exec rspec <path>` |
| `package.json` with `"jest"` key | `npx jest <path>` |
| `package.json` with `"vitest"` key | `npx vitest run <path>` |
| `pyproject.toml` or `pytest.ini` or `setup.cfg` | `pytest <path>` |

If multiple markers are present the order above determines priority. When no
marker matches, the skill prints an error asking the operator to set
`GITGIT_TEST_RUNNER` (e.g. `export GITGIT_TEST_RUNNER="bundle exec rspec"`).

## Output

```
PASS  spec/services/session_spec.rb  (exit 0)
```

or

```
FAIL  spec/services/session_spec.rb  (exit 1)
```

## Implementation

The implementation lives in `lib/run-spec.sh`. Runner detection and test
execution are split into testable functions so the BATS test suite can
exercise them without launching a real test run.
