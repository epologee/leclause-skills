# gurus

Opinionated code review panel. Eight expert perspectives weigh in on the current diff, each from their own engineering philosophy. Useful when a single reviewer voice would miss trade-offs that another tradition would flag immediately.

## Panel

| Guru | Lens |
|------|------|
| Kent Beck | TDD, simplicity, intent-revealing names |
| Martin Fowler | Refactoring, code smells, expressive interfaces |
| Robert C. Martin (Uncle Bob) | Clean Code, SOLID, no comments |
| David Heinemeier Hansson | Conceptual compression, Rails idioms, no ceremony |
| Sandi Metz | Object-oriented design, message passing, POODR rules |
| Tobi Lutke | Pragmatism at scale, monolith-friendly, ship-it ethos |
| Rich Hickey | Simplicity over easy, value-oriented programming, immutability |
| Thoughtbot | Pattern catalogue, test discipline, gem ecosystem |

## Commands

### `/gurus`

Runs the panel against the full codebase by default; pass an explicit scope (file, directory, or commit range) to narrow the review. Each guru returns a short critique, and consensus across 6 of 8 produces an action plan. The value sits in the tension between perspectives: agreement across fundamentally different styles is a strong signal.

## When to use

- Before merging a non-trivial PR
- When refactoring touches conceptual boundaries
- When you suspect "looks fine to me" is missing something a different tradition would catch

## Subagents

The plugin ships `gurus:sonnet-max`, a generic subagent pinned to Sonnet at maximum effort (`model: sonnet`, `effort: max` in frontmatter). The eight guru dispatches route through this subagent so every voice runs on the same engine ceiling. The definition lives in `agents/sonnet-max.md`; consumers who upgrade from pre-1.0.8 need `claude plugins update gurus@leclause` before the next `/gurus` call, otherwise the dispatch fails with an unknown subagent_type.

## Installation

```bash
/plugin install gurus@leclause
```
