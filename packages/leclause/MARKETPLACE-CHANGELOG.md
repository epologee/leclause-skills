# leclause marketplace changelog

Marketplace-wide news. Per-plugin changes go in
`packages/<plugin>/CHANGELOG.md` and surface via
`/leclause:whats-new <plugin>`. This file covers the ecosystem:
new plugins joining, plugins leaving, marketplace-level
conventions, shared infrastructure, breaking changes that
touch every plugin author at once.

The format is dated sections (`## [YYYY-MM-DD]`), latest at
the top. `/leclause:whats-new` (no argument) prints the most
recent section. Patch-level marketplace tweaks that change
nothing observable are intentionally silent.

## [2026-08-11]

### Migration

- **`gurus` moves without renaming.** Install `gurus@laicluse-agent-fieldkit`, then uninstall `gurus@leclause`; the four skill names are unchanged.

## [2026-06-11]

### Migration

- **`autonomous` splits in two on its way to laicluse-agent-fieldkit.** The mission framework moves to `rover@laicluse-agent-fieldkit` (`/autonomous:rover` is now `/rover:rover`, same rename for prepare, decide, pride, trim, verify, stop, rover-help); the successor `autonomous@laicluse-agent-fieldkit` keeps only the keepalive/cron/wake layer, which the rover pulls in by itself in interactive sessions. Install both, then uninstall `autonomous@leclause`. Existing `.autonomous/` loop files stay readable.

## [2026-06-10]

### Migration

- **`anger-management` moves without renaming and becomes multi-agent.** Install `anger-management@laicluse-agent-fieldkit`, then uninstall `anger-management@leclause`. The friction pile moves to `${LAICLUSE_HOME:-~/.laicluse}/anger-management/`; existing captures migrate automatically on the next capture or repair.

## [2026-06-09]

### Changed

- **`@leclause` is entering maintenance mode.** New multi-agent-compatible work moves to `epologee/laicluse-agent-fieldkit` under the `@laicluse-agent-fieldkit` marketplace alias.
- **Install the successor marketplace before removing this one.** `claude plugins marketplace remove leclause` uninstalls remaining `@leclause` plugins when this is the last configured scope.

### Migration

- **`how-plugins-work` keeps its plugin name.** Install `how-plugins-work@laicluse-agent-fieldkit`, then uninstall `how-plugins-work@leclause` when the new copy works for you.
- **`gitgit` moves as `git-discipline`.** Install `git-discipline@laicluse-agent-fieldkit`, then uninstall `gitgit@leclause` when the replacement covers your workflow.
- **`self-improvement` moves without renaming.** Install `self-improvement@laicluse-agent-fieldkit`, then uninstall `self-improvement@leclause` once the new copy is active.
- **`intervision` moves without renaming and becomes multi-agent.** Install `intervision@laicluse-agent-fieldkit`, then uninstall `intervision@leclause`; the successor adds a Codex side that consults Claude via `claude -p`.
- **Plugins not listed here remain in `@leclause` for now.** Migrate one plugin at a time; remove the whole marketplace only after nothing you use still comes from it.

## [2026-05-07]

### Breaking

- **`inspiratie` plugin renamed to `inspire`.** The slash command is now `/inspire` and the install line becomes `claude plugins install inspire@leclause`. Existing installs of `inspiratie@leclause` no longer receive updates; uninstall the old name and install the new one. Sister plugins (`autonomous`, `gurus`, `dont-do-that`, `self-improvement`) updated their cross-references in the same release.
- **`/do-that` renamed to `/duh` inside `dont-do-that`.** The user-invocable slash command and its sister Stop guard with the `[dont-do-that/duh]` error code flip together. Retrain muscle memory.

### Added

- **`dont-do-that` gains the `/just-a-question` skill.** Sister to `/duh` and inverse in shape: `/duh` resolves ambiguity into action, `/just-a-question` locks action down. The operator types `/just-a-question` to mark a message as a question for information, not a request for change, so a clarifying conversation cannot silently tip into mid-question code edits. Read-only tools only; obvious fixes get named, not applied.

## [2026-05-06]

### Added

- **Post-update broadcast pattern adopted across the
  marketplace.** Every plugin that has a slash command now
  ships `bin/check-broadcast` plus a `CHANGELOG.md` skeleton
  plus a `<post-update-broadcast>` block in its entry skill,
  wired up via the new `bin/adopt-broadcast` script.
  `testing-philosophy` is the only exception (no slash
  command for the broadcast to attach to). Empty CHANGELOGs
  stay silent; plugins broadcast only when an author lands a
  real `## [vX.Y.Z]` section.
- **`bin/check-broadcast.mjs` is now the single canonical
  source.** Per-plugin `bin/check-broadcast` files are
  byte-for-byte mirrors maintained by `bin/sync-check-broadcast`
  and policed by the pre-commit hook. Plugin authors edit
  the canonical, run the sync, and the rest of the rollout
  is mechanical.

### Changed

- **Marketplace README adoption recipe.** The old
  three-step manual copy-paste is replaced with a one-liner:
  `bin/adopt-broadcast <plugin> [<entry-skill>]`. Re-running
  on an already-adopted plugin is a safe no-op.
