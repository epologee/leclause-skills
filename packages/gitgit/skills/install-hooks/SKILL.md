---
name: install-hooks
user-invocable: true
description: >
  Install gitgit's four git-native hooks (commit-msg, prepare-commit-msg,
  post-commit, pre-push) into the current repo so commits and pushes done
  outside Claude Code (CLI, IDE, another tool) still get the body-schema
  validation and wip-gate enforcement. Run once per clone. Use --force to
  overwrite existing hooks.
argument-hint: "[--force] [--dry-run]"
---

# Install Hooks

Place gitgit's four git-native hooks into the current repo, so commits
and pushes made outside of Claude Code are also guarded.

The four hooks:

| Hook | Purpose |
|------|---------|
| `commit-msg` | Validates the commit message against `validate-body.sh` (the same lib as the PreToolUse guard). |
| `prepare-commit-msg` | Pre-fills the editor window with a structured body template based on the staged diff. |
| `post-commit` | Detects `--no-verify` usage and logs it to `~/.claude/var/gitgit-no-verify.log`. |
| `pre-push` | Re-runs the wip-gate on the push range: commits with `Slice: wip` are blocked. |

## Why

The PreToolUse:Bash guard (slice 4) only covers Claude-driven commits.
Commits made directly via `git commit` from the shell or from an IDE
do not see this guard. Claude Code does not offer a native
`PreCommit` lifecycle event and will not get one
(https://github.com/anthropics/claude-code/issues/4834 closed not planned),
so the per-repo git-native hooks are the only way to cover non-Claude commits
and pushes.

All hooks share the same `validate-body.sh` as the PreToolUse guard, so
behavior never diverges.

## What the skill does

1. Verifies that we are inside a git repo (`git rev-parse --git-dir`).
2. Detects whether `core.hooksPath` is set, and picks the correct target
   directory (`.git/hooks/` or the value of `core.hooksPath`).
3. Finds the plugin install path via `~/.claude/plugins/installed_plugins.json`
   and bakes that absolute path into each hook (placeholder
   `__PLUGIN_INSTALL_PATH__` is replaced). Re-running after a plugin update
   refreshes the path.
4. Per hook (`commit-msg`, `prepare-commit-msg`, `post-commit`,
   `pre-push`), copies the source from the plugin to the target dir, sets
   the executable bit, and logs the result.

## Defaults and flags

- Default: per hook, when the target file already exists with different
  content, the skill refuses to overwrite and prints the diff. Idempotent: an
  existing file with identical content is a silent no-op.
- `--force`: makes a backup for each conflicting hook
  (`<hook>.bak.<timestamp>`) and then overwrites.
- `--dry-run`: shows what would happen without writing anything.

## How to use

```bash
# Standard install in the current repo:
bash "$(jq -r '.plugins["gitgit@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/skills/install-hooks/lib/install.sh"

# Or via the skill invocation:
/gitgit:install-hooks
/gitgit:install-hooks --dry-run
/gitgit:install-hooks --force
```

The skill runs `lib/install.sh` from this skill directory. The script
detects the plugin install path itself via `installed_plugins.json` and
needs no further arguments.

## Conflict detection and escape hatches

- Existing hook with different content without `--force`: skill prints a
  unified diff (`diff -u`), refuses to overwrite, and exits 1.
- Existing hook with identical content: silent no-op (idempotent).
- `--no-verify` on `git commit` remains a valid escape for the author;
  the installed `post-commit` logs that usage to
  `~/.claude/var/gitgit-no-verify.log` so it is auditable after the fact.
- The magic comment `# vsd-skip: <reason>` in the body skips validation
  and logs to `~/.claude/var/gitgit-skips.log` (handled by
  `validate-body.sh`).

## Example output

```
gitgit:install-hooks
  hooks dir   : .git/hooks (default)
  plugin path : ~/.claude/plugins/cache/epologee/gitgit/1.0.30
  installed   : commit-msg
  installed   : prepare-commit-msg
  installed   : post-commit
  installed   : pre-push
  skipped     : (none)
  backups     : (none)
done.
```

With a conflict without `--force`:

```
gitgit:install-hooks
  hooks dir : .git/hooks
  WARN: .git/hooks/commit-msg already exists with different content.
  --- existing
  +++ new
  @@ -1,3 +1,5 @@
  ...
  Refusing to overwrite. Re-run with --force to backup-and-replace.
exit 1
```

## Post-update procedure

After every `claude plugins update gitgit@leclause`, the baked plugin path in
the installed hooks is stale. Run in every repo where the hooks are active:

```bash
/gitgit:install-hooks --force
```

This replaces the existing hooks (with automatic backup) and bakes in the
new path. Without this step the hooks will try to source the old plugin
path on the next commit, which can fail if the cache directory has been
cleaned up.
