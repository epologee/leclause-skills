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

## [v1.0.117]

### Fixed

- **Commit guards no longer fire on `git commit` as substring.** A `for f in ... ; head "$f"; done` with a filename like `gitgit commit discipline.md`, a `grep -n "git commit" ...`, or an `echo "...git commit..."` passes cleanly. Quoted strings and heredoc bodies are stripped before the gate, and a left-side word boundary anchors the match.

## [v1.0.112]

### Changed

- **Rule 1 banlist widened.** `Land`, `Make`, `Work`, `Do`, `Get`, `Tweak`, `Surface`, `Address`, and `Apply` now deny at subject start. Rewrite the subject to name the actual capability change.

## [v1.0.111]

### Added

- **Rotation Rule 15 (`steiger`): no internal AI-tooling vocabulary in commit subject/body.** Targets skill names, phase terms, and politer rewrites like "consensus reached"; surfaces on rotation, not a hard block.

## [v1.0.107]

### Breaking

- **Strict commit-discipline is the default.** `GITGIT_AUTONOMOUS=1` is gone (rules apply universally); bare `Red-then-green: yes`, `Visual: n/a` on UI-touch, `Verified: build-only`, and `# vsd-skip` are always rejected. `--no-verify` is the only audit-logged noodknop.

## [v1.0.106]

### Breaking

- **New required `Verified:` trailer.** Anchors how the change was verified: `operator-confirmed`, `<artefact path>`, `red-then-green`, `build-only`, or `n/a (reason)`. Drops on Slice opt-outs; `build-only` is rejected under `GITGIT_AUTONOMOUS=1`. See `/gitgit:commit-discipline`.

## [v1.0.102]

### Added

- **`/gitgit:disable-git` and `/gitgit:enable-git` lock the repo for Claude.** While the lock is on, git mutations are denied; read-only inspection (status, log, diff, show, blame) keeps working. With `/gitgit:install-hooks` active, CLI `git commit` and `git push` are blocked too.

## [v1.0.94]

### Fixed

- **Migration of the legacy global state file no longer poisons
  new repos.** The first repo after v1.0.92 used to leave the
  global file in place, re-migrating stale rotation state into
  every later new repo. The source is now renamed to `*.migrated`
  after a successful copy.
- **Toplevel-hash portability on systems without `shasum`.** The
  fallback chain dropped to `cksum` (decimal CRC), drifting per-
  toplevel paths into a different alphabet. It now tries `md5sum`
  and `md5 -q` first, with a final degradation to the global path
  when no hex hasher exists.

### Changed

- **Empty `git rev-parse HEAD` is denied with guidance.** A
  `git commit` in a zero-commit repo used to silently lose the
  ack; the deny is now explicit: "cannot read HEAD, is this a new
  repository?" (Landed as v1.0.90; documented retroactively.)

## [v1.0.93]

### Changed

- **Deny strings are now English.** The rotation guard mixed
  Dutch and English; it is now uniformly English (`violates`,
  `password missing or wrong`, `Paste`). The ack placeholder is
  `<password>`. Tooling that grepped old fragments needs to update.

## [v1.0.92]

### Changed

- **Rotation state file is now per-repo, not per-user.** The
  global path collided across unrelated repos. It is now
  namespaced by an 8-char hash of `git rev-parse --show-toplevel`.
  The legacy file migrates atomically on first read; worktrees of
  the same repo share state.

## [v1.0.91]

### Changed

- **State file format is now key=value.** Was positional
  (line 1 = pv, ...); now `pv=-1`, `pr=-1`, `rp=0`,
  `ack_pending_sha=`. The reader still accepts legacy 3- and
  4-line forms. Tooling using `sed -n '<N>p'` should switch to
  `grep -E '^<key>='`.
- **Migration of the legacy `dont-do-that` state file is now
  atomic.** The one-shot `cp` could be raced by two Claude sessions
  starting at once; the migration now writes to a per-pid temp file
  and renames atomically.

## [v1.0.89]

### Changed

- **Broken-install deny replaces the slash-command fallback.** When
  `commit-subject.sh` cannot resolve `SKILL.md`, it now emits a loud
  `install appears broken: ... Reinstall gitgit@leclause.` deny
  instead of degrading to `/gitgit:commit-discipline`. Reinstall if
  you see this.

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
  New code `red-then-green-autonomous`. The trailer must anchor the
  claim with `<path>` (staged), `<path>:<test-name>`, or `n/a
  (reason >= 10 chars)`. Outside autonomous mode `yes` still works.

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

- **`# vsd-skip` no longer bypasses UI-touched commits.** New code
  `vsd-skip-ui-touch`. UI commits must use `Visual: <path>` or
  `Visual: n/a (rationale)`. Backend / spec / migration commits are
  unaffected.

### Added

- **`GITGIT_AUTONOMOUS=1` strict mode for unattended commits.**
  When set, `# vsd-skip` is rejected outright
  (`vsd-skip-autonomous`) and `Visual: n/a` is rejected on UI-
  touched commits (`visual-na-autonomous`; only `Visual: <path>`).
  Ship from rover skills to tighten policy.

## [v1.0.57]

### Added

- **Post-update broadcasts.** After an update, the next gitgit slash
  command shows a one-line summary of what changed. Runs once per
  machine per version; sentinel at
  `~/.claude/var/leclause/gitgit-broadcast-seen`.
- **Shared `/leclause:whats-new gitgit` reader.** Re-prints this file's
  section for the current version on demand, regardless of whether the
  broadcast already fired. The reader lives in the new `leclause` plugin
  and works for any leclause plugin that adopts the broadcast pattern.
