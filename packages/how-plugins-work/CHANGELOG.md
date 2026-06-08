# how-plugins-work changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new how-plugins-work` to re-read at any time.

Categories:

- **Breaking**: user must adapt
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
The helper writes the sentinel only when stdout is non-empty, so a CHANGELOG
without a `## [vX.Y.Z]` section stays silent on every update.

## [v1.0.31]

### Added

- **Cross-agent sync vocabulary.** The skill now explains how to keep shared `SKILL.md` sources, Claude manifests, Codex manifests, marketplace indexes, and runtime caches in separate source/adapter/cache roles.

## [v1.0.27]

### Changed

- **Haiku no longer suggested as a subagent target.** Token-savings example lists Sonnet only (Sonnet has its own usage allocation; Haiku does not); the factual reference about supported `model` values still includes `haiku`.
