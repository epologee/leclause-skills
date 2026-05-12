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

## [v1.0.6]

### Added

- `drydry:drydry` orchestrator with two explicit modes: quick (ad-hoc "is this duplicate?" check, inline answer with verifier-grep) and audit (full sweep producing a `<name>-drydry-findings.md` artefact). User-invocable entry point.
- `drydry:sweep` (agent-only): runs a Sonnet subagent with verifier-burden discipline; hits without a runnable verifier are dropped.
- `drydry:checklist` (agent-only): bootstraps a six-to-ten item checklist for a named domain (iOS/SwiftUI, Rails, React/TypeScript, Markdown prose, design tokens).
- `drydry:triage` (agent-only): three-bucket triage (cheap-and-safe, partial, needs-design) with convergence cost per item.
- `drydry:learn` (agent-only): online research on de-duplication state-of-the-art via parallel WebSearch and WebFetch subagents.
- `drydry:upstream` (agent-only): cross-toolbox audit against framework offerings (Rails/Devise, SwiftUI/Foundation, React conventions).
- `drydry:instructions` (agent-only): CLAUDE.md audit for instructions that themselves cause DRY violations.
