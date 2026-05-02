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

## [v1.0.61]

### Breaking

- **`# vsd-skip` no longer bypasses UI-touched commits.** Previously the
  magic-comment opt-out worked on any commit. It now refuses commits where
  the UI-touch heuristic fires (SwiftUI / UIKit / AppKit `.swift`,
  `.tsx` / `.jsx` / `.vue` / `.svelte` / `.html` / `.css` / `.scss`,
  `.erb` / `.haml` / `.slim`, `.storyboard` / `.xib`, `.xcassets/`),
  with new error code `vsd-skip-ui-touch`. UI commits must use
  `Visual: <path>` (screenshot in the repo) or `Visual: n/a (rationale)`
  instead. Backend / spec / migration commits are unaffected. Rationale:
  `vsd-skip` was structurally being used to defer screenshots to "a later
  phase" that rarely materialised, defeating the Visual gate on the
  commits that needed it most.

### Added

- **`GITGIT_AUTONOMOUS=1` strict mode for unattended commits.** When the
  env var is set (intended for rover / autonomous-loop scenarios), two
  extra rules apply: `# vsd-skip` is rejected outright with code
  `vsd-skip-autonomous`, and `Visual: n/a (rationale)` is rejected on
  UI-touched commits with code `visual-na-autonomous` (only
  `Visual: <path>` accepted, file-must-exist still enforced). Ship the
  env var from your rover skill before invoking `git commit` to enforce
  the stricter policy without affecting interactive sessions.

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
