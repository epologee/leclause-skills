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

## Installation

```bash
/plugin install gurus@leclause
```
