# autonomous changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new autonomous` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.91]

### Added

- **Rover Tool-gap is not a destination.** Mid-mission tool-gaps (capturing a screenshot, transcribing audio, rendering a diagram) are now DRIVE work, not STANDBY triggers; the rover scans loaded skills, deferred tools, PATH, and sibling projects before declaring STANDBY.

## [v1.0.76]

### Changed

- INSPECT findings are now weighed via a three-fates rubric (fix, cost-value-skip with structured rationale, or reject-as-non-issue with pride's second-pass evidence). Cost is output weight (lines, files, maintenance burden), not work effort.

### Added

- Trim is a new sixth INSPECT pass, biased toward subtraction. It runs after gurus and before STOW, asks what got added that does not earn its weight, and is a hard gate; STOW does not start without a `Trim findings:` log entry.
- `/autonomous:trim` user-invocable command runs the same subtraction-pass against `main..HEAD` plus uncommitted changes for use outside a rover session.
