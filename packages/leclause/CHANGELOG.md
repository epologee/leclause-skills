# leclause changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new leclause` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.15]

### Changed

- **`gurus` now points to its successor marketplace.** Install `gurus@laicluse-agent-fieldkit`, then uninstall `gurus@leclause`; the four skill names are unchanged.

## [v1.0.9]

### Changed

- **`@leclause` is entering maintenance mode.** Add the successor with `claude plugins marketplace add epologee/laicluse-agent-fieldkit`; migrate plugins one at a time.
- **Do not remove the `leclause` marketplace first.** Removing a marketplace from its last scope also uninstalls every plugin installed from it.
