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

## [v1.0.89]

### Changed

- **Broken-install deny replaces the slash-command fallback.** When
  `commit-subject.sh` cannot resolve the absolute path to its
  `SKILL.md` (broken install, layout regression, stale cache), the
  guard now emits a loud `install appears broken: cannot resolve
  SKILL.md path. Reinstall gitgit@leclause.` deny instead of
  degrading to the slash-command form `(zie /gitgit:commit-discipline)`,
  which silently re-introduced the grep-fishing v1.0.83 was meant to
  fix. Reinstall gitgit@leclause if you see this message.

## [v1.0.85]

### Changed

- **Rotation advances on confirmed commit success, not on PreToolUse
  ack-match.** Previously the rotation slot moved the moment the ack
  matched in PreToolUse, which meant a commit that passed PreToolUse
  but failed at commit-msg (missing `[doublecheck]`, version-bump
  hook error, etc.) still consumed a rotation slot. The guard now
  records the HEAD sha at ack-match and advances `rotation_pos` only
  when the next dispatcher entry sees that HEAD has moved. When the
  commit fails, the slot stays and the operator acks the same rule
  again on retry. The state file gains a fourth line
  (`ack_pending_sha`); older three-line files are read with that
  field defaulted to empty, so no migration step is required.

## [v1.0.83]

### Changed

- **Rotation deny output points at the SKILL.md absolute path.** The
  rotation reminder used to end with `(zie /gitgit:commit-discipline)`,
  which sent Claude grep-fishing through the plugin cache to find the
  password. The deny now ends with `(lookup: <abs-path>, section
  'Rotation reminders')` so the lookup is a direct Read instead. The
  password is not pre-revealed; the lookup itself stays required, and
  the discipline (one rule per commit, hook-delivered, no
  reflex-compliance from a wall of rules) is unchanged. Tests or
  tooling that grep for the old `(zie /gitgit:commit-discipline)`
  string need to update.

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
