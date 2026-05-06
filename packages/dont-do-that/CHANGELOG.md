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
