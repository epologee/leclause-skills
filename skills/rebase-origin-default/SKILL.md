---
name: rebase-origin-default
description: >
  Rebase current branch on the remote default branch (main/master).
  Never fetches origin automatically, but warns when the tracking ref
  is stale. Resolves simple merge conflicts automatically.
user-invocable: true
allowed-tools: Bash(git rev-parse:*), Bash(git ls-remote:*), Bash(git rebase:*), Bash(git rev-list:*), Bash(git add:*), Bash(git diff:*), Bash(git status:*), Bash(git symbolic-ref:*)
optional: true
scope: global
---

# /rebase-origin-default Skill

Rebase the current branch on the remote default branch. Before rebasing, verify that the tracking ref is in sync with the remote. Never fetch automatically, because fetching has side effects on `--force-with-lease` safety.

## Step 0: Detect Default Branch

Determine the default branch name:

```bash
git symbolic-ref refs/remotes/origin/HEAD
```

This returns something like `refs/remotes/origin/main`. Extract the branch name (e.g. `main`). Use this as `$DEFAULT` throughout the remaining steps.

If this fails (ref not set), fall back: check which of `main` or `master` exists as a remote tracking branch via `git rev-parse --verify`. Use whichever exists. If both exist, prefer `main`. If neither exists, stop and ask the user.

## Step 1: Staleness Check

Check if `origin/$DEFAULT` matches the remote without fetching. Run these as **separate Bash calls**:

```bash
git rev-parse refs/remotes/origin/$DEFAULT
```
```bash
git ls-remote origin refs/heads/$DEFAULT
```

Compare the SHAs:

- **If they match:** proceed to Step 2.
- **If they differ:** show a warning and **stop**:
  ```
  origin/$DEFAULT is stale (local: <short-sha>, remote: <short-sha>).
  Run `git fetch origin` first, then invoke /rebase-origin-default again.
  ```
  Do NOT proceed with the rebase. Do NOT fetch. The user must fetch explicitly because fetching updates all remote tracking refs, which affects `--force-with-lease` behavior on other branches.

## Step 2: Pre-rebase State

Record the current state so the user can assess the rebase afterward:

```bash
git rev-list --left-right --count origin/$DEFAULT...HEAD
```

Report: `Branch is <ahead> commits ahead, <behind> commits behind origin/$DEFAULT.`

If the branch is 0 commits behind, report `Already up to date with origin/$DEFAULT.` and stop.

## Step 3: Rebase

```bash
git rebase origin/$DEFAULT
```

- **If the rebase succeeds cleanly:** proceed to Step 4.
- **If the rebase hits conflicts:** proceed to Step 3a.

## Step 3a: Resolve Conflicts

When a rebase stops on conflicts:

1. Read each conflicting file to understand both sides.
2. Resolve the conflicts. Use your understanding of the codebase and the intent of both sides to produce the correct merge. Prefer the branch's intent when it deliberately diverges from the default branch (that's the point of the branch). Prefer the default branch's version for incidental changes (renames, formatting, new imports).
3. Stage the resolved files and continue:
   ```bash
   git add <resolved-files>
   ```
   ```bash
   git rebase --continue
   ```
4. Repeat if the rebase stops on further commits.
5. If a conflict is genuinely ambiguous (both sides made intentional, incompatible changes to the same logic), stop and describe the conflict to the user instead of guessing.

## Step 4: After Rebase

Report the result with a prefix: how many commits ahead of origin/$DEFAULT, and whether conflicts were resolved (and if so, which files). No proactive suggestions beyond that. The user will push or take further action when ready.
