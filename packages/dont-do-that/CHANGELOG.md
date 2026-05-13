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

## [v1.0.52]

### Added

- **New PreToolUse guard `no-code-comments`.** Blocks Edit, Write, MultiEdit that add a code comment to a programming-language file. Pass: `https?://` URL, `allow-comment: <reason>` (colon required), pragma at body start (`@ts-ignore`, `noqa`, ...), or shebang on line 1.

### Note

- **Doc comments (`///`, `//!`, `/** */`) count as comments** and are blocked. Use `allow-comment: generates API docs` if your Swift/Rust/JSDoc project relies on source-derived documentation.
- **JSX (`.jsx`) and TSX (`.tsx`) are excluded** because text content between JSX tags can legitimately contain `//`. Plain `.js`/`.ts` files are still checked.

## [v1.0.48]

### Breaking

- **`/do-that` is renamed to `/duh`.** Slash command, SKILL directory, and the sister Stop guard with its `[dont-do-that/duh]` error code flip together. Retrain muscle memory.

## [v1.0.46]

### Changed

- **`/do-that` now covers declarations of inability.** After "I can't see this" or "I don't have access", `/do-that` signals: find a path via a different tool, wider scope, or `/inspire:inspire`. The skill names the lesson so it persists.

## [v1.0.45]

### Added

- **New `/just-a-question` skill.** Marks a message as a question, not a request for change. Claude answers with read-only tools only; `Edit`, `Write`, and mutating Bash are off the table for the turn. Imperatives get named, not applied. `/do-that` is the exit.

### Changed

- **`/do-that` menu has no upper bound.** The "two or three options" cap is gone: every distinct candidate from the previous turn is listed, even ten, and the operator picks. Truncation counts as picking in disguise.
- **`/do-that` no longer collapses options across actors.** Two candidates with different actors (operator vs assistant) used to rationalize as "already disambiguated, run mine". Both are now listed regardless of actor.

## [v1.0.41]

### Added

- **New Stop guard `do-that`.** Blocks Stop when the assistant offers a
  recipe (`Run \`cmd\``, `open the URL`) for an action it could have run
  itself. Pass: run it, or prefix with `Instructie:` for an explicit
  manual recipe. 🚧 skips this guard.
- **New user-invocable skill `/do-that`.** Type `/do-that` when the
  previous turn offered a recipe instead of executing; the skill resolves
  the proposal and runs it. Multiple candidates trigger a numbered "A or
  B?" prompt. Inviolable gates are not lifted.

### Fixed

- **`do-that` guard now matches real Dutch prose.** Pattern A's `[^.\n]`
  hit the letter `n` between `je kunt` and `door` and never reached the
  keyword; replaced with `[^.]`. The imperative pattern also now matches
  after sentence terminators, not only after newlines.
