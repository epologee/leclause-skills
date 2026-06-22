# bonsai (deprecated)

`bonsai` has moved to **`laicluse-agent-fieldkit`** as
`bonsai@laicluse-agent-fieldkit`. The successor is a cross-platform CLI for the
worktree lifecycle: `create`, `setup`, and `prune` (teardown), exposed through
the `bonsai`, `setup`, and `prune` skills.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## What changed

- No more clipboard / `cd … && claude "…"` start command, and no macOS-only
  requirement. Bonsai now emits facts (`create --json` returns the worktree,
  branch, base, and a dev-server port hint) and launches nothing; whatever runs
  an agent in the worktree composes its own briefing.
- Teardown is behind a hard safety gate: a clean-but-non-integrated worktree is
  kept unless explicitly forced, and removal warns on orphaned commits.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install bonsai@laicluse-agent-fieldkit
claude plugins uninstall bonsai@leclause
```
