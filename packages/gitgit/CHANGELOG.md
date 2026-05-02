# gitgit changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use `/leclause:whats-new gitgit`
to re-read at any time.

Categories:

- **Breaking**: user must adapt (renamed commands, removed flags, hook gates)
- **Added**: new commands, new optional behavior
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.

## [v1.0.57]

### Added

- **Post-update broadcasts.** After a plugin update, the next time you run
  `/gitgit:commit-all-the-things` (or any other gitgit slash command in this
  pattern), gitgit shows a one-line summary of what changed in the new
  version. Runs once per machine per version; the sentinel lives at
  `~/.claude/var/leclause/gitgit-broadcast-seen`.
- **Shared `/leclause:whats-new gitgit` reader.** Re-prints this file's
  section for the current version on demand, regardless of whether the
  broadcast already fired. The reader lives in the new `leclause` plugin
  and works for any leclause plugin that adopts the broadcast pattern.
