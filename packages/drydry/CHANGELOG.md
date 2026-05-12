# drydry changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new drydry` to re-read at any time.

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

### Added

- `/drydry:drydry`: one user-invocable command that routes between two modes. Quick mode answers "is this duplicate?" inline with a runnable verifier-grep and no artefact. Audit mode produces a `<scope>-drydry-findings-<timestamp>.md` artefact with a detection-method paragraph and a triaged findings list.
- `/drydry:drydry learn <topic>`: explicit one-off enrichment that researches de-duplication patterns from external sources and writes proposals to `<project_root>/.drydry/learnings/`. The next audit reads `robust`-confidence proposals automatically; `probable` and `fragile` proposals stay write-only until the operator promotes them.
