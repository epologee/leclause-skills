# gitgit

Bundle of git-write skills plus a commit-discipline hook stack. The skills
land the day-to-day git operations Claude Code needs (commit-all-the-things,
snipe, rebase-latest-default, merge-to-default), and the hooks enforce a
structured commit body schema across both Claude-driven commits
(PreToolUse:Bash) and direct CLI commits (git-native hooks installed per repo).

## Wat

`gitgit` does two things at once:

1. **Day-to-day git skills.** Eight user-invocable skills that cover the
   commit / rebase / merge flows the operator runs over and over.
2. **Commit-discipline enforcement.** Two-layer hook architecture
   (PreToolUse guards plus git-native hooks) that validates a structured
   body schema: subject + WHY paragraph + Slice / Tests / Red-then-green
   trailers parsed via `git interpret-trailers`, with seven opt-out enum
   tokens and an evidence cache that backs the trailer claims.

Reference for the schema, examples, escape-hatches, and troubleshooting:
`/gitgit:commit-discipline`.

## Skills

| Skill | Command | Auto |
|-------|---------|:----:|
| commit-all-the-things | `/gitgit:commit-all-the-things` | yes |
| commit-snipe | `/gitgit:commit-snipe` | yes (on the word "snipe") |
| rebase-latest-default | `/gitgit:rebase-latest-default` | yes |
| merge-to-default | `/gitgit:merge-to-default` | yes |
| commit-discipline | `/gitgit:commit-discipline` | |
| install-hooks | `/gitgit:install-hooks` | |
| run-spec | `/gitgit:run-spec` | |
| saw-red | `/gitgit:saw-red` | |

- **commit-all-the-things** inspects `git status` plus `git diff`, groups
  changes by intent (feature, fix, refactor, docs, config), and creates
  one commit per group. Dutch trigger phrases also fire it: "commit
  alles", "ruim de working tree op".
- **commit-snipe** stages only the files (or hunks) that belong to the
  current conversation's work and leaves the rest untouched. Auto-fires
  on the word "snipe".
- **rebase-latest-default** rebases the current branch on the freshest
  default branch (local or `origin/<default>`), resolves trivial conflicts
  where safe, and stops on non-trivial conflicts.
- **merge-to-default** lands the current branch on the project's default
  with a github-style `--no-ff` merge commit, rebases on conflict, deletes
  the local source branch after the merge is confirmed, and no-ops with a
  TUI warning when invoked on the default branch itself. Push remains an
  explicit user action.
- **commit-discipline** is the canonical reference for the body schema,
  error-codes, opt-out enum, and escape-hatches.
- **install-hooks** copies the git-native `commit-msg`, `prepare-commit-msg`,
  `post-commit`, and `pre-push` hooks into the current repo so commits
  made outside Claude Code still get validated. `--force` overwrites
  existing hooks (a backup is taken automatically); `--dry-run` previews.
- **run-spec** runs a single test/spec file through the project's
  auto-detected runner (RSpec, Jest, Vitest, Go test, pytest) and writes a
  green/red entry to the test-runner cache.
- **saw-red** writes a RED cache entry for a spec path you observed
  failing outside `/gitgit:run-spec` (IDE, terminal, CI), enabling the
  `Red-then-green: yes` trailer to validate once a subsequent green run
  is recorded.

## Hooks

PreToolUse:Bash dispatcher chain (`hooks/dispatch.sh`):

| Guard | Triggers on | Blocks |
|-------|-------------|--------|
| `git-dash-c.sh` | any `git -C <dir>` command | `git -C` (keeps Claude Code's prefix-based permissions clean) |
| `commit-format.sh` | `git commit` | editor-mode commits without `-m` |
| `commit-subject.sh` | `git commit -m` | subjects past 50/72, lowercase first, trailing period |
| `commit-body.sh` | `git commit -m` | bodies that fail `validate-body.sh` |
| `commit-trailers.sh` | `git commit -m` | `Co-Authored-By:` with `@anthropic.com` email |
| `push-wip-gate.sh` | `git push` | push range containing a `Slice: wip` commit |

Git-native hooks (installed per-repo via `/gitgit:install-hooks`,
sourced from `skills/commit-discipline/git-hooks/`):

| Hook | Purpose |
|------|---------|
| `commit-msg` | runs `validate-body.sh` on every non-Claude commit |
| `prepare-commit-msg` | pre-fills the editor with a layer-classified template |
| `post-commit` | logs `--no-verify` usage to `~/.claude/var/gitgit-no-verify.log` |
| `pre-push` | re-runs the wip-gate on the push range |

Both layers source the same `hooks/lib/validate-body.sh`, so behavior never
diverges between Claude-driven and CLI-driven commits.

## Install

```bash
claude plugins install gitgit@leclause
```

The PreToolUse:Bash hooks register automatically. To also catch commits
made outside Claude Code (CLI, IDE, another tool), install the git-native
hooks into each repo:

```bash
/gitgit:install-hooks
```

Use `--dry-run` to preview, `--force` to overwrite existing hooks. Re-run
after each `claude plugins update gitgit@leclause` so the installed hooks
point at the current plugin version.

### Migration from the standalone plugins

`commit-all-the-things@leclause` and `rebase-latest-default@leclause` used
to ship as separate plugins. Both standalone entries have been removed from
the marketplace; uninstall the leftover copies so the slash commands route
to the bundled versions:

```bash
/plugin uninstall commit-all-the-things@leclause
/plugin uninstall rebase-latest-default@leclause
```

## Voorbeeld commit-message

```
Drop invalid meter reading on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in analytics.
This change keeps the transaction event but discards just the bad
reading, restoring the visibility we lost.

Tests: spec/services/session_spec.rb#start_event_with_bad_reading,
       spec/services/session_spec.rb#stop_event_with_bad_reading
Slice: handler + service + spec
Red-then-green: yes
Resolves: https://example.org/backlog/issues/1234
```

The `Slice` value can also be one of seven opt-out tokens: `docs-only`,
`config-only`, `migration-only`, `chore-deps`, `revert`, `merge`, `wip`.
Opt-out commits drop the `Tests:` requirement; the documentation /
config / chore-deps tokens additionally drop the `Red-then-green:`
requirement.

## Bypass

Five escape-hatches, each logged for later auditing:

- `# vsd-skip: <reason>` magic comment in the body (logged to
  `~/.claude/var/gitgit-skips.log`)
- `git commit --no-verify` (logged to `~/.claude/var/gitgit-no-verify.log`
  via the `post-commit` hook)
- `GITGIT_ALLOW_AI_COAUTHOR=1` to allow a single `@anthropic.com`
  `Co-Authored-By:` trailer
- `GITGIT_ALLOW_WIP_PUSH=1` or the magic-comment `# allow-wip-push` to
  push a range that contains `Slice: wip` commits (logged to
  `~/.claude/var/gitgit-wip-pushes.log`). Note: `# allow-wip-push` only
  works when Claude issues the push (the PreToolUse:Bash guard reads the
  bash command string). For terminal-issued `git push`, only
  `GITGIT_ALLOW_WIP_PUSH=1` works.
- `GITGIT_TRIVIAL_OK=1` to skip body-validation for a single trivial commit
  (set automatically by the PreToolUse guard for diffs of <= 1 file and
  <= 5 insertions)

See `/gitgit:commit-discipline` for the full schema, opt-out matrix, and
troubleshooting guide.

## Test-runner cache (optional)

When `GITGIT_TEST_CACHE_REQUIRED=1` is set in the environment, the body
validator additionally checks every path in the `Tests:` trailer against
the test-runner cache (`~/.claude/var/gitgit-test-runs.log`). Use
`/gitgit:run-spec <path>` to log a run, `/gitgit:saw-red <path>` to log a
manual red observation. With the cache required, `Red-then-green: yes`
also requires a red entry preceding a green entry within the cache window.

The cache is opt-in (default off) so existing flows keep working; the
required-mode is for operators who want stronger evidence behind the
trailer claims.

## Test suite

```bash
bash packages/gitgit/test/run-bats              # 200+ BATS cases
bash packages/gitgit/test/smoke/smoke-test.sh   # 22-case end-to-end smoke
```

The BATS suite is split per concern:

- `validate-body/` covers the body schema rules from sections 5.5 and 6.6
  of the plan.
- `block-mode/`, `shadow-mode/`, `wip-gate/`, `template-fill/` cover the
  guard glue per slice.
- `install-hooks/` covers the per-repo install scenarios (empty repo,
  existing hooks, `core.hooksPath`, worktree).
- `migrated-hooks/`, `migration/` cover the `dont-do-that` to `gitgit`
  migration parity.
- `test-cache/` covers the opt-in test-runner cache.

The smoke suite spins up disposable git repos and exercises the full hook
chain end-to-end.

## Audit

After a mission run, verify that no body-less commits slipped through.
The script ships inside the plugin at `bin/audit-no-body-commits`; resolve
its path from the active install so it survives plugin updates:

```bash
GITGIT=$(jq -r '.plugins["gitgit@leclause"][0].installPath' \
  ~/.claude/plugins/installed_plugins.json)
python3 "$GITGIT/bin/audit-no-body-commits"
python3 "$GITGIT/bin/audit-no-body-commits" --branch main --since 2026-04-01
python3 "$GITGIT/bin/audit-no-body-commits" --exclude-trivial
```

Lists every commit on the branch with a single-line message (or below the
trivial threshold), useful for verifying that slice 4 block-mode actually
held during a mission.
