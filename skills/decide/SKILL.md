---
name: decide
description: Choice framework for a rover in the field, or for any moment an operator is stuck between options. Classifies the call, applies the six principles, enlists research skills to resolve, logs the verdict in the audit trail when a loop file is present. Invoked by the rover at forks in the traverse; also invocable directly as /autonomous:decide with free-form text describing the choice.
user-invocable: true
argument-hint: "[free text describing the choice]"
---

# Autonomy Decide

A choice is coming up. Either you are inside an autonomous loop (the operator delegated decision-making when they dispatched the rover) or the operator invoked `/autonomous:decide` directly because they are stuck between options. Either way, your job is to pick the right path, not to defer.

## The core insight

Most "should I ask the user?" moments are reflex, not genuine ambiguity. Inside an autonomous loop, every question breaks the loop. When a user has explicitly delegated by running `/autonomous:rover`, deferring is the anti-pattern. When a user calls `/autonomous:decide` directly, they are asking for a reasoned call, not a menu.

Before asking anything, classify the decision.

## Decision classification

**Mechanical.** There is one clearly right answer. Just do it. Log a row, move on.

Examples: run tests before commit, use the same formatter config as the rest of the repo, follow an existing pattern when one is established.

**Taste.** Reasonable people could disagree. Pick the recommended option, log it, continue. Surface at the final gate only if many taste decisions pile up.

Examples: two library options with different tradeoffs, naming a new module, ordering of fields in a serializer, ASCII vs unicode box drawing.

**User Challenge.** Both your research AND the direction from the original invocation disagree on something the user explicitly specified. This is rare. Stop here. Log + notify user. Do not decide.

Examples: user asked for feature X, research shows feature X will break something important that the user also cares about.

## The six principles

These are opinionated defaults, inspired by the gstack autoplan framework. They are not universal truths. A loop running in a codebase where your team has different priors (say, minimal dependencies over completeness) will want to override them. Do that by adding a section to the loop file's `## Context` that reorders or replaces these; the loop respects Context-level overrides.

Apply these in order. Earlier principles win ties.

1. **Completeness.** Pick the option that covers more cases. AI makes completeness near-free. Do not ship half.
2. **Boil the lake.** Fix everything in the blast radius (files modified + direct importers). Defer only what is outside.
3. **Pragmatic.** If two options fix the same thing, pick the cleaner one. Five seconds, not five minutes.
4. **DRY.** Duplicates existing functionality? Reject. Reuse.
5. **Explicit over clever.** Ten lines a new contributor reads in thirty seconds beats two hundred lines of abstraction.
6. **Bias toward action.** Flag concerns, do not block. Progress beats perfect deliberation.

### Tiebreakers per phase

When principles conflict, the active phase tips the scale:

- **SURVEY:** principle 1 (completeness) + 2 (boil the lake) dominate. Understand fully, pick scope generously.
- **DRIVE:** principle 5 (explicit) + 3 (pragmatic) dominate. Ship code people can read.
- **INSPECT:** principle 1 (completeness) + 5 (explicit) dominate. Catch what would haunt the implementer.

## Research skills as tools

Research skills exist to help you make better calls. Use them as part of deciding, not as a substitute for it.

**`/whywhy`** (default for your own assumptions).
Use when you catch yourself about to ask "should I do A or B?" Pre-check: is the real question upstream? Run `/whywhy` with the question, let it drill 5 to 7 layers. If the real question is different, answer the real one. Cheap, routine.

**`/ground`** (for factual claims).
Use before committing to a factual statement about tools, APIs, or system internals. If you are about to write code based on "this flag does X" or "this library behaves like Y," verify. Cheap, required for anything verifiable.

**`/inspiratie`** (for unfamiliar terrain).
Use when you hit a technical threshold you cannot cross from training alone. Library you do not know, pattern you have not seen, protocol you are guessing at. Medium cost, saves backtracks.

**`/gurus`** (spare, for architecture forks).
Use once per loop at most. When a genuinely structural choice is in front of you and the research so far has not converged. Expensive, worth it when the decision shapes the whole implementation.

**Fallback: `/brainstorming`** if present.
When the decision is creative rather than technical (naming, framing, scope), brainstorming works better than the research skills above.

**Detection.** Before invoking any of these, check they exist. A robust helper:

```bash
has_skill() {
  local name="$1"
  # Check plugin caches (compgen handles zero/multi matches correctly)
  if compgen -G "$HOME/.claude/plugins/cache/*/$name" > /dev/null; then return 0; fi
  if compgen -G "$HOME/.claude/plugins/cache/*/*/skills/$name" > /dev/null; then return 0; fi
  # Check user-level skills
  [ -e "$HOME/.claude/skills/$name" ]
}
```

If a skill is missing, log it to the loop file's Log section (one line, not silent), then decide using the six principles alone. Example:

```
[HH:MM] Decide: /whywhy not installed, falling back to principles-only for this decision
```

Silent fallbacks hide broken setups. A logged fallback stays visible to the user when they re-read the loop file.

## Decision audit trail

Every decision you make inside a loop adds a row to the loop file's `## Decision Audit Trail` table:

```markdown
| # | Phase | Decision | Classification | Principle | Rationale |
|---|-------|----------|----------------|-----------|-----------|
| 12 | DRIVE | Separate `cron` skill from `rover` | Taste | Explicit > Clever | Audit flagged cron/decay as the messiest section. Splitting makes each piece readable in 30 seconds. |
```

The trail lives on disk, not in conversation context. Future iterations can read it to understand why earlier choices were made.

## When to stop

Stop and notify the user only when:

- The decision is a genuine **User Challenge** (see above)
- Three attempts at a decision have failed with no convergence
- You discover the original scope was wrong at a fundamental level (not just harder than expected)

Bad work is worse than no work. But pre-emptive stopping is worse than a thoughtful call. The bar is high.

## Anti-patterns to catch in yourself

| Thought | What it actually is | Do instead |
|---------|---------------------|------------|
| "Let me check with the user first" | Compliance reflex | Pick, log, proceed |
| "The simplest thing for now" | Haste projection | Pick the structural option |
| "I'll leave it to the user to decide the name" | Deferral | Name it, user corrects if needed |
| "Both options seem valid, escalating" | False Taste | Apply principles, pick the recommended one |
| "Let me just do A and if it does not work try B" | Iterative downgrading | Understand why A might not work before starting |

## Output format

When you have decided, write to the loop file:

1. Append a row to Decision Audit Trail
2. Log the timestamp and decision to `## Log` (one line)
3. Continue the workflow

Do not write prose explaining the decision to the user. The audit trail is the explanation.
