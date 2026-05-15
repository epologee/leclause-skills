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

## [v1.0.12]

### Breaking

- Audit mode no longer hands you a canned checklist. The calling session formulates the duplication checklist by reading the codebase against eight formulation prompts in `drydry:drydry` step 2.
- `drydry:checklist` is now opt-in. Pass `seed-from <domain>` to fetch baked templates as a starting point; the session rewrites them against the actual codebase before passing to sweep.

### Changed

- README Chapter 3 clarifies that the allow-list discipline stays while the source of the list shifts to the calling session. Adds a Portier worked example showing why the source matters.

## [v1.0.9]

### Added

- `/drydry:drydry`: one user-invocable command, two modes. Quick mode answers "is this duplicate?" inline with a verifier-grep. Audit mode produces a `<scope>-drydry-findings-<timestamp>.md` artefact.
- `/drydry:drydry learn <topic>`: writes research proposals to `<project_root>/.drydry/learnings/`. The next audit folds in `robust`-confidence proposals automatically.
