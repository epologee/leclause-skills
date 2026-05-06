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
Version numbers may therefore be non-contiguous (an internal refactor bumps
the version without producing an entry here).

## [v1.0.94]

### Fixed

- **Migration of the legacy global state file no longer poisons new
  repos.** The first repo opened after the v1.0.92 namespacing change
  copies the global state file into its per-toplevel path; the
  global file used to remain in place and silently re-migrate into
  every subsequent new repo, propagating stale rotation_pos. The
  source is now renamed to `*.migrated` after a successful copy, so
  the second and later new repos start fresh.
- **Toplevel-hash portability on systems without `shasum`.** The
  fallback chain previously degraded to `cksum`, which produces a
  decimal CRC; the per-toplevel state-file paths drifted into a
  different alphabet and collided in unexpected ways. The fallback
  now tries `md5sum` and `md5 -q` (both yield hex), with a
  documented final degradation to the global path when no hex
  hasher is available at all.

### Changed

- **Empty `git rev-parse HEAD` is denied with guidance.** When a
  `git commit` runs in a brand-new repo with zero commits, the
  rotation guard previously wrote an empty `ack_pending_sha` and
  silently lost the ack. The deny is now explicit: "cannot read
  HEAD, is this a new repository? Make at least one commit before
  invoking the rotation." (The change landed as v1.0.90; this entry
  covers it retroactively.)

## [v1.0.93]

### Changed

- **Deny strings are now English.** The rotation guard's deny output
  used to mix English and Dutch (`overtreedt`, `wachtwoord onjuist
  of ontbreekt`, `Plak`, `verbergt subject`, `reminder. Plak`); it
  is now consistently English (`violates`, `password missing or
  wrong`, `Paste`, `hides the subject`, `reminder. Paste`). The ack
  template placeholder is `<password>` instead of `<wachtwoord>`.
  The rotation passwords themselves (`gedrag`, `loep`, `essentie`,
  etc., listed in the rotation table) stay Dutch by design; they
  are referential to each rule's principle and form the per-cycle
  exposure mechanism. Tooling that grepped for the old
  Dutch fragments needs to update.

## [v1.0.92]

### Changed

- **Rotation state file is now per-repo, not per-user.** The path
  `~/.claude/var/gitgit-commit-rule-state` was a single global file
  shared by every repo on the machine; two worktrees of different
  repos collided on `rotation_pos` and `ack_pending_sha`. The path
  is now namespaced by an 8-character hash of
  `git rev-parse --show-toplevel` (e.g.
  `~/.claude/var/gitgit-commit-rule-state-3f7a2c11`). On first read
  for a new repo the per-toplevel file does not exist; the legacy
  global file (if present) migrates atomically into the new
  location. Worktrees of the same repo share state, which is the
  natural scope for the discipline.

## [v1.0.91]

### Changed

- **State file format is now key=value.** The rotation state file at
  `~/.claude/var/gitgit-commit-rule-state` was a positional flat
  text file (line 1 = `pending_violation`, line 2 = `pending_rotation`,
  line 3 = `rotation_pos`, line 4 = `ack_pending_sha`). It is now a
  key=value file (`pv=-1`, `pr=-1`, `rp=0`, `ack_pending_sha=`),
  self-describing and tolerant of field reordering or future
  extension. The reader still accepts both legacy positional formats
  (three-line and four-line); the next write converges the file to
  key=value. Existing installations migrate without operator
  intervention. Tooling that read the file via `sed -n '<N>p'` needs
  to switch to `grep -E '^<key>='`.
- **Migration of the legacy `dont-do-that` state file is now atomic.**
  The one-shot `cp` from the legacy path could be raced by two
  Claude sessions starting simultaneously; the migration now writes
  to a per-pid temp file and renames atomically.

## [v1.0.89]

### Changed

- **Broken-install deny replaces the slash-command fallback.** When
  `commit-subject.sh` cannot resolve the absolute path to its
  `SKILL.md` (broken install, layout regression, stale cache), the
  guard now emits a loud `install appears broken: cannot resolve
  SKILL.md path. Reinstall gitgit@leclause.` deny instead of
  degrading to a slash-command pointer (`/gitgit:commit-discipline`),
  which silently re-introduced the grep-fishing v1.0.83 was meant to
  fix. Reinstall gitgit@leclause if you see this message.

## [v1.0.85]

### Changed

- **Rotation slot only advances after a commit actually lands.** A commit that passed PreToolUse but failed downstream (missing `[doublecheck]`, version-bump hook error) used to burn a slot anyway; now you ack the same rule again on retry.

## [v1.0.83]

### Changed

- **Rotation deny names the SKILL.md path.** The reminder ends with `(lookup: <abs-path>, section 'Rotation reminders')` instead of `(zie /gitgit:commit-discipline)`, so the password lookup is a direct Read; tooling that greps for the old phrase needs an update.

## [v1.0.80]

### Breaking

- **`Red-then-green` line+name forms are unified.** The bare
  `<path>:<line>` and bare `<path>:<test-name>` forms are removed.
  Use the combined form `<path>:<line> # <test-name>` instead. A
  full example trailer:

  ```
  Red-then-green: spec/foo_spec.rb:42 # SomeClass#method does the thing
  ```

  The `# ` separator is the RSpec / Cucumber wire format and is the
  only candidate that keeps `path:line` clickable in iTerm2 Semantic
  History, VSCode terminalLinkParsing, and Ghostty. The gcc-style
  `path:line: <name>` form was rejected because two of those three
  parsers greedily absorb the trailing non-numeric continuation past
  the second colon, breaking cmd-click; see
  https://github.com/microsoft/vscode/issues/127762 and
  https://github.com/ghostty-org/ghostty/discussions/11378 for the
  upstream confirmations. The file-only `<path>` form, the `yes`
  self-attestation, and `n/a (reason >= 10 chars)` are unchanged.

  New error code `red-then-green-line-out-of-range` fires when the
  named line exceeds the staged blob's line count or names line 0
  (the trailer uses 1-based numbering, matching every test runner's
  output). `red-then-green-test-not-found` continues to fire when
  the named test does not match any `it / describe / context /
  specify / @test / @Test / Scenario / func / def` declaration in
  the staged blob.

## [v1.0.73]

### Breaking

- **`Red-then-green: yes` is rejected under `GITGIT_AUTONOMOUS=1`.**
  New error code `red-then-green-autonomous`. Bare self-attestation was
  the easiest hallucination path: an unattended agent had every incentive
  to type `yes` without ever having seen a red phase. Under autonomous
  mode the trailer must now anchor the claim: name the spec as
  `<path>` (must be in the staged diff) or `<path>:<test-name>` (test
  name must match an `it / describe / context / specify / @test / @Test /
  Scenario / func / def` declaration in the staged blob), or fall back
  to `n/a (reason >= 10 chars)`. Outside autonomous mode `yes` still
  works.

### Added

- **`Red-then-green` accepts spec-path forms.** Three new shapes on top
  of the legacy `yes` and `n/a (reason)`:

  - `Red-then-green: spec/foo_spec.rb` anchors the claim to a spec file
    that this commit actually touches. New error code
    `red-then-green-path-not-in-staged` rejects random spec names.
  - `Red-then-green: spec/foo_spec.rb:starts on StartTransaction`
    identifies WHICH test was seen red, by name. New error code
    `red-then-green-test-not-found` fires when the staged blob has no
    matching `it / describe / context / specify / @test / @Test /
    Scenario / func / def` declaration.
  - `Red-then-green: spec/foo_spec.rb:42` is the line-number form; the
    staged blob must have at least that many lines.

  The validator cannot prove that the test was actually run red, but it
  can refuse claims that are not anchored anywhere. See
  `/gitgit:commit-discipline` for the full table.

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
