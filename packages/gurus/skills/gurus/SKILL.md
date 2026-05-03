---
name: gurus
user-invocable: true
description: Orchestrator die tussen de guru-panels kiest. `gurus:software` voor code review door acht engineering-personas. `gurus:council` voor abstracte beslissingen door vijf adversariële lenzen plus chairman-synthese. Gebruik deze skill wanneer je /gurus hebt getypt zonder suffix en nog niet weet welk panel bij de vraag past.
allowed-tools:
  - Skill
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git status *)
  - Bash(git branch *)
effort: high
---

> **Preflight.** The sub-skills dispatch via `gurus:sonnet-max`. That agent exists from plugin version 1.0.8 onward. If the dispatch fails with "unknown subagent_type: gurus:sonnet-max", run `claude plugins update gurus@leclause` and try again.

# Gurus Orchestrator

Two panels live under this plugin:

- **`gurus:software`** does opinionated code review with eight engineering personas (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). Consensus across 6+/8 yields an action plan.
- **`gurus:council`** critiques a decision or idea with five adversarial lenses (pre-mortem, first-principles, opportunity-finder, stranger, action), anonymous peer review, and chairman synthesis.

This orchestrator decides which panel fits the question.

## Routing

### Implicit signal from context

Read the context before asking the user anything. Beyond the conversation you may call `git status`, `git log`, and `git diff` to check recent code activity; the frontmatter allows this.

- **Software** is the right panel when:
  - The conversation discusses a diff, code change, or codebase review
  - The user names a file or directory to review
  - Recent commits exist and the question feels like "is dit goed?"
  - The user uses words like "review", "refactor", "smell", "structure"
  - The user asks a technical correctness question ("does this regex do X?", "is this query right?"); this is not a decision but a code question and falls under software
  - The user pastes a code snippet. Pass that snippet as an explicit scope via `args` so the software skill does not accidentally scan the whole codebase

- **Council** is the right panel when:
  - The question is a trade-off or decision ("moet ik X of Y?"), not a question about code correctness
  - The topic is strategic, product-oriented, or interpersonal
  - The user wonders whether Claude was just being agreeable ("was ik te hard voor je?" is a signal)
  - The question contains no concrete technical correctness question

**Tiebreaker when both signals fire.** A "should I use a service object here?" mixes a decision form ("should I") with code context. In that case: default to **software**, because the code is the ground truth; mention in the proposal line that council also fits and offer the override explicitly.

Example tiebreaker proposal:

> You are asking whether to use a service object, and you have code in context. Two panels fit. Routing to **software** (code as ground truth). Type `council` to get a design-decision review instead.

### Default and override

Determine a default based on the signals and present it to the user. Example:

> I see a recent diff on `packages/foo/`. Routing to **`gurus:software`**. Type `council` to switch to the adversarial panel.

Or:

> Your question reads as a strategic choice without code context. Routing to **`gurus:council`**. Type `software` to get a code review.

When there is direct explicit intent (the user said "council" or "software" in their message) skip this check and dispatch immediately.

### No signal

When context is empty or both panels are equally plausible, ask one short question:

> Two panels available: `software` for code review, `council` for a decision or idea. Which fits?

Ask this question **once**. The user's answer is binding; do not confirm again.

## Dispatch

After routing: invoke the chosen panel via the Skill tool. For software use `skill="gurus:software"`; for council use `skill="gurus:council"`. The `args` contain the concrete question or scope the user provides.

**When the user typed `/gurus:gurus` without accompanying text**, there is no literal question to pass on. Synthesize a one-sentence summary of the current topic from the conversation (optionally enriched with the output of `git status` or `git log -1`) and pass that as `args`. Keep the summary neutral; no framing that steers the panel toward a particular verdict.

**When the user pasted a code snippet**, pass that snippet as explicit scope in `args` so `gurus:software` does not scan the full codebase but only the snippet (and optionally the surrounding file the user mentioned).

The sub-skills take over. This orchestrator does not do any review itself.

## Rules

- **Routing is fast.** At most one question to the user before dispatching. Every second question is a failure mode.
- **Explicit intent wins.** When the user already named `software` or `council` in the invocation, skip the routing step and dispatch directly.
- **Do not review yourself.** This skill only presents the choice and delegates. Substantive review happens in the sub-skill.
- **Stay neutral between panels.** Present both as legitimate; the context determines which fits, not which panel is "better".
