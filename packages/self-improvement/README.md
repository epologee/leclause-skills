# self-improvement

Update CLAUDE.md and skills based on user feedback. Detects duplication, determines optimal location for new instructions, and extracts large sections into standalone skills when CLAUDE.md gets too long.

## Commands

### `/self-improvement`

Reads recent feedback from the conversation, decides where it belongs (user CLAUDE.md, project CLAUDE.md, or a skill), and applies the change. May add, edit, shorten, merge, or remove existing instructions.

## Auto-trigger

Activates when the user:

- gives feedback on Claude behavior ("don't do that", "do this instead")
- says "remember this" or "onthou dit"
- asks to create or improve skills
- asks to improve CLAUDE.md instructions

## Pruning is part of the job

The skill is allowed to delete, shorten, merge, or simplify, not just append. Instruction files grow over time; regular trimming keeps them readable. Less text that gets read beats more text that gets skipped.

## Installation

```bash
/plugin install self-improvement@leclause
```
