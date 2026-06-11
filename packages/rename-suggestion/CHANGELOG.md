# rename-suggestion changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new rename-suggestion` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.18]

### Changed

- **Clipboard helper resolves successor-first.** The resolver now tries
  `clipboard@laicluse-agent-tools` before the legacy `clipboard@leclause`
  install; the generic `pbcopy`/`xclip`/`clip.exe` fallback is unchanged.

## [v1.0.17]

### Changed

- **Clipboard step names `clipboard@leclause` as default with fallback.** The resolver tries the helper first; if not installed, pipe the rename to whichever clipboard tool your environment has (`pbcopy`, `xclip`, `clip.exe`). Ghost-text still works either way.
