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

## [2026-05-07]

### Added

- **`dont-do-that` gains the `/just-a-question` skill.** Sister to `/do-that` and inverse in shape: `/do-that` resolves ambiguity into action, `/just-a-question` locks action down. The operator types `/just-a-question` to mark a message as a question for information, not a request for change, so a clarifying conversation cannot silently tip into mid-question code edits. Read-only tools only; obvious fixes get named, not applied.

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
