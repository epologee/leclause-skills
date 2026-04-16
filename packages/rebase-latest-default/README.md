# rebase-latest-default

Rebase the current branch on the latest default branch (local or remote). Determines whether `main`, `master`, or `origin/main` is further ahead and rebases on the best target. Resolves simple merge conflicts automatically.

## Commands

### `/rebase-latest-default`

1. Detects the default branch name (`main` or `master`) via `git symbolic-ref refs/remotes/origin/HEAD`.
2. Compares local default vs `origin/<default>` to pick the freshest target.
3. Rebases the current branch on the chosen target.
4. Resolves trivial conflicts (whitespace, identical edits, lockfile regenerations) where safe.
5. Stops and surfaces non-trivial conflicts for manual resolution.

## When to use

- Before opening a PR, to keep the history linear
- After a long-lived branch falls behind the default
- Whenever a colleague mentions "rebase your branch first"

## Installation

```bash
/plugin install rebase-latest-default@leclause
```
