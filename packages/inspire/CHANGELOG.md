# inspire changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new inspire` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.7]

### Breaking

- **Plugin renamed from `inspiratie` to `inspire`.** The slash command is now `/inspire` (instead of `/inspiratie`). The marketplace install line becomes `claude plugins install inspire@leclause`. Existing installs of `inspiratie@leclause` will no longer receive updates; uninstall the old name and install the new one. All cross-references in sister plugins (`autonomous`, `gurus`, `dont-do-that`, `self-improvement`) have been updated in this same release.
