# gurus changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new gurus` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.35]

### Changed

- **`/gurus:software` panel composition shifts: Ousterhout in, Thoughtbot out.** John Ousterhout brings the scope-cutting lens from *A Philosophy of Software Design* (deep modules, defining errors out of existence). Panel size and 6+/8 threshold unchanged.

## [v1.0.34]

### Changed

- **Sibling-skill references use suggestion-with-fallback.** `gurus:software` and `gurus:writers` recommend `/auto-loop` for autonomous handoff with a fallback for sessions that lack it; stop-mechanism examples cover both `/auto-loop` and `/autonomous:stop`.

## [v1.0.29]

### Changed

- Eric Evans replaces Tobi Lutke on the `/gurus:software` panel; size and 6+/8 threshold unchanged. Evans brings the domain-modeling lens (ubiquitous language, bounded contexts, aggregates, anti-corruption layers) the panel was missing.
