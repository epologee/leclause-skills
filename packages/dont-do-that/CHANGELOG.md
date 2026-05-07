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

- **`/do-that` is renamed to `/duh`.** The slash command, the SKILL directory, and the sister Stop guard with its `[dont-do-that/duh]` error code all flip together. Retrain muscle memory; nothing else changed.

## [v1.0.46]

### Changed

- **`/do-that` now covers declarations of inability.** When the previous turn said "I can't see this", "I can't verify that", or "I don't have access", `/do-that` is the operator's signal to spend tokens finding the path: a different local tool, a different scope, or the internet via `/inspire:inspire` for unfamiliar stacks/libraries/APIs. After the action succeeds, the skill names the workflow lesson ("Learned: to verify X here, `Y` works") so the path persists for next time. Slash-command references to the renamed `inspire` plugin replace the old `inspiratie` form.

## [v1.0.45]

### Added

- **New `/just-a-question` skill.** The operator types `/just-a-question` to mark a message as a question for information, not a request for change. Claude answers using read-only tools only (`Read`, `Glob`, `Grep`, read-only `Bash`); `Edit`, `Write`, `NotebookEdit`, and mutating Bash are off the table for the rest of the turn. Even when the message reads as an imperative ("fix X"), the prefix overrides: obvious fixes get named, not applied. `/do-that` remains the natural exit.

### Changed

- **`/do-that` menu has no upper bound.** The earlier disambiguation rule capped the menu at "two or three options"; when the previous turn presented more candidates the rule said "do nothing and ask what they meant" rather than listing them. The cap is gone: the operator now sees every distinct option from the previous turn (even ten) and picks. Truncation is flagged as picking in disguise.
- **`/do-that` no longer collapses options across actors.** When the previous turn presented two candidates with different actors (one operator-side, one assistant-side), the actor-split used to rationalize as "already disambiguated, run mine." The skill now lists both regardless of actor and asks. Different actor does not collapse two options to one.

## [v1.0.41]

### Added

- **New Stop guard `do-that`.** Sister to `verify`. Blocks Stop when the
  assistant offers a recipe (`je kunt dit doen door \`cmd\` te draaien`,
  `you can verify this by running \`cmd\``, `Run \`cmd\` to see the result`,
  `open the URL in your browser`) for an action it could have executed
  itself via Bash, Edit, or browser tools. Fenced code blocks are stripped
  first so documentation examples do not self-trigger. Pass condition:
  actually run the action and report the result, or prefix the line with
  `Instructie:` when the operator explicitly asked for a manual recipe. The
  WIP escape hatch 🚧 also skips this guard.
- **New user-invocable skill `/do-that`.** Read-time counterpart to the
  `do-that` guard. The operator types `/do-that` (no arguments) when the
  previous assistant turn offered a recipe, instruction, browser action, or
  confirmation question instead of executing the proposal. The skill
  resolves the proposal from that previous turn and runs it via the
  available tools. The proposal must be exactly one super-clear
  non-ambiguous action; if multiple distinct candidates exist in the
  previous turn, the skill mandates a short "A or B?" disambiguation prompt
  (two or three numbered options, one line each, no advice) before any
  execution. Inviolable gates (push, merge to default, deploy, destructive
  git, external irreversible ops) are not lifted.

### Fixed

- **`do-that` guard now matches real Dutch prose.** Pattern A used the
  negated class `[^.\n]`, which in grep ERE means "not period, not
  backslash, not letter n" (the `\n` inside a character class is read as
  the literal letters `\` and `n`, not as a newline escape). The gap
  between `je kunt` and `door` hit `n` inside the first word and never
  reached the keyword, so the guard never fired on real Dutch prose.
  Replaced with `[^.]`. The imperative pattern was anchored on
  `(^|\n)`, so a `Run cmd` that followed a sentence on the same line was
  missed; relaxed to also match after sentence terminators.
