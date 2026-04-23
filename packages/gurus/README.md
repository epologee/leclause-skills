# gurus

Opinionated panels that challenge a decision from multiple perspectives. Two panels live under this plugin: `software` for code review, `council` for critical thinking on an idea or decision. An orchestrator skill routes between them.

## Sub-skills

| Skill | Use for | Panel |
|-------|---------|-------|
| `gurus:software` | Code review | Eight engineering personas (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). Consensus across 6 of 8 yields an action plan. |
| `gurus:council` | A decision or idea | Five adversarial lenses (pre-mortem, first-principles, opportunity-finder, stranger, action) plus anonymised peer review plus chairman synthesis. |
| `gurus:gurus` | Orchestrator: you are not sure which panel fits | Reads the context (diff present or abstract question), proposes a default, lets you override, then dispatches. Not itself a review; only a router. |

## Commands

### `/gurus`

Entry orchestrator. Routes to `gurus:software` when a diff or code scope is in context, to `gurus:council` when the question reads like a decision or idea. Propose the default in one line, accept a one-word override (`software` or `council`), then dispatch. Direct invocation of `/gurus:software` or `/gurus:council` skips the routing step.

### `/gurus:software`

Runs the software panel against the full codebase by default; pass an explicit scope (file, directory, or commit range) to narrow the review. Each guru returns a short critique, and consensus across 6 of 8 produces an action plan. The value sits in the tension between perspectives: agreement across fundamentally different styles is a strong signal.

### `/gurus:council`

Runs five advisors against a brief. Every advisor writes a lens-specific review (pre-mortem assumes the idea fails, first-principles strips assumptions, opportunity-finder seeks the adjacent bigger win, stranger answers with zero context, action demands a concrete next step). Responses are anonymised, peers blind-review each other, and a chairman synthesises one verdict plus one concrete next step. Pattern based on Ole Lehmann's "board of advisors" skill, itself inspired by parallel LLM-critique patterns that Andrej Karpathy (among others) has advocated. Single-vendor variant: all voices on `gurus:sonnet-max`.

One invocation dispatches eleven `gurus:sonnet-max` agents at `effort: max` (five lenses, five peer reviews, one chairman). The two review phases run in parallel, so typical wall time is 2 to 4 minutes; token cost is substantial. See `skills/council/SKILL.md` for the full panel, lens briefings, and prompt templates. See `skills/software/SKILL.md` for the eight-guru software panel.

## When to use which

- **Before merging a non-trivial PR**: `gurus:software`.
- **When refactoring touches conceptual boundaries**: `gurus:software`.
- **When "moet ik X of Y?" is the actual question**: `gurus:council`.
- **When Claude's previous answer felt sycophantic**: `gurus:council`.
- **When you are not sure**: `/gurus` and let the orchestrator decide.

## Subagents

The plugin ships `gurus:sonnet-max`, a generic subagent pinned to Sonnet at maximum effort (`model: sonnet`, `effort: max` in frontmatter). Every guru and every advisor dispatches through this subagent so every voice runs on the same engine ceiling. The definition lives in `agents/sonnet-max.md`; consumers who upgrade from pre-1.0.8 need `claude plugins update gurus@leclause` before the next invocation, otherwise the dispatch fails with an unknown subagent_type.

## Installation

```bash
/plugin install gurus@leclause
```
