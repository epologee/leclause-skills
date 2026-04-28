# gitgit

Bundle of git-write skills for Claude Code. The plugin owns four user-invocable commands that cover the everyday cycle of staging, committing, rebasing, and merging local work onto the project's default branch.

## Commands

### `/gitgit:commit-all-the-things`

Inspects `git status` and `git diff`, groups changes by intent (feature, fix, refactor, docs, config), and creates one commit per group. Each commit message follows the project's commit conventions (read from CLAUDE.md and recent `git log`). Dutch trigger phrases also fire it: "commit alles", "ruim de working tree op", "commit what's left".

### `/gitgit:commit-snipe`

Precision commits when the working tree contains modifications from multiple unrelated tasks. Stages only the files (or hunks) that belong to the current conversation's work and leaves the rest untouched. Use when `commit-all-the-things` would over-commit.

### `/gitgit:rebase-latest-default`

Rebases the current branch on the latest version of the default branch. Detects the default name (`main` or `master`) via `git symbolic-ref refs/remotes/origin/HEAD`, compares local default vs `origin/<default>` to pick the freshest target, runs `git rebase`, and resolves trivial conflicts (whitespace, identical edits, lockfile regenerations) where safe. Stops on non-trivial conflicts for manual resolution.

### `/gitgit:merge-to-default`

Lands the current branch on the project's default branch with a true `--no-ff` merge commit (the same shape GitHub's merge button produces, two parents preserved). Steps:

1. Detect the default branch.
2. If currently on the default branch, surface a TUI warning and exit (no-op safeguard).
3. Run `gitgit:commit-all-the-things` so any pending working-tree changes land on the source branch first.
4. Switch to the default branch and run `git merge --no-ff <source>`.
5. On conflict, abort the merge, switch back to the source branch, run `gitgit:rebase-latest-default`, then retry the merge from a clean tree.
6. Report the merge commit SHA, the file list, and whether a rebase preceded the merge.

Push remains an explicit user action. The skill does not push.

## Installation

```bash
/plugin install gitgit@leclause
```

## Behavior

- Reads project + user CLAUDE.md to pick up commit-message style, branch policy, and any opt-outs.
- Stages files individually rather than `git add -A`, so secrets and large binaries are not pulled in by accident.
- Never pushes. Push remains an explicit user action.
- `merge-to-default` produces a real merge commit (`--no-ff`), never a fast-forward, never a squash.
