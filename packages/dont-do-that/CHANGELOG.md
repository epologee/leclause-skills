# dont-do-that changelog

Each entry corresponds to the `version` in `.claude-plugin/plugin.json`. The
post-update broadcast (see `bin/check-broadcast`) shows the section for the
currently-installed version exactly once per machine. Use
`/leclause:whats-new dont-do-that` to re-read at any time.

Categories:

- **Breaking**: user must adapt (renamed guards, changed escape tokens, hook
  gates that now block previously-accepted output)
- **Added**: new guard, new user-invocable skill, new escape hatch
- **Changed**: non-breaking adjustments worth knowing about
- **Fixed**: silent unless the bug was user-visible

Patch-level fixes that change nothing the user can observe are intentionally
omitted; the broadcast budget is for things the user benefits from knowing.
Version numbers may therefore be non-contiguous.

## [v1.0.48]

### Breaking

- **`/do-that` is renamed to `/duh`.** Slash command, SKILL directory, and the sister Stop guard with its `[dont-do-that/duh]` error code flip together. Retrain muscle memory.

## [v1.0.46]

### Changed

- **`/do-that` now covers declarations of inability.** When the previous turn said "I can't see this" or "I don't have access", `/do-that` is the signal to find a path: a different tool, a wider scope, or `/inspire:inspire` for unfamiliar stacks. After success the skill names the workflow lesson ("Learned: to verify X here, `Y` works") so it persists. Slash-command references switch from `inspiratie` to `inspire`.

## [v1.0.45]

### Added

- **New `/just-a-question` skill.** Marks a message as a question for information, not a request for change. Claude answers with read-only tools only (`Read`, `Glob`, `Grep`, read-only `Bash`); `Edit`, `Write`, `NotebookEdit`, and mutating Bash are off the table for the turn. Imperatives like "fix X" get named, not applied. `/do-that` is the natural exit.

### Changed

- **`/do-that` menu has no upper bound.** The "two or three options" cap is gone: every distinct candidate from the previous turn is listed, even ten, and the operator picks. Truncation counts as picking in disguise.
- **`/do-that` no longer collapses options across actors.** Two candidates with different actors (operator vs assistant) used to rationalize as "already disambiguated, run mine". Both are now listed regardless of actor.

## [v1.0.41]

### Added

- **New Stop guard `do-that`.** Sister to `verify`. Blocks Stop when the
  assistant offers a recipe (`je kunt dit doen door \`cmd\` te draaien`,
  `Run \`cmd\` to see the result`, `open the URL in your browser`) for an
  action it could have run itself via Bash, Edit, or browser tools. Fenced
  code blocks are stripped first. Pass condition: run the action and
  report, or prefix the line with `Instructie:` when the operator asked
  for a manual recipe. The WIP escape hatch 🚧 also skips this guard.
- **New user-invocable skill `/do-that`.** Read-time counterpart to the
  guard. Type `/do-that` when the previous turn offered a recipe,
  instruction, browser action, or confirmation question instead of
  executing. The skill resolves the proposal and runs it. Multiple
  candidates trigger a short "A or B?" disambiguation prompt (numbered
  options, one line each, no advice). Inviolable gates (push, merge to
  default, deploy, destructive git, external irreversible ops) are not
  lifted.

### Fixed

- **`do-that` guard now matches real Dutch prose.** Pattern A's `[^.\n]`
  in grep ERE means "not period, not backslash, not letter n", so the gap
  between `je kunt` and `door` hit `n` and never reached the keyword.
  Replaced with `[^.]`. The imperative pattern, anchored on `(^|\n)`,
  missed `Run cmd` after a sentence on the same line; relaxed to also
  match after sentence terminators.
