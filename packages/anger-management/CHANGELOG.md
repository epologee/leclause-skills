# anger-management changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new anger-management` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.2]

### Added

- New plugin. Curse at the agent with `/fuck`, `/shit`, `/crap`, `/wtf`, `/bullshit`, or `/damn` to capture one cheap friction line to a global log and move on, no fix demanded in the moment.
- `/anger-management:repair` is the cooled-down fix pass: a go/no-go verdict (nothing / not-enough-signal / fix) that routes a real recurring problem to `/self-improvement`, or changes nothing when the pattern is unclear. `/anger-management` stays a quick read-back of the pile.
