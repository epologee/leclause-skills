# ground

Verify Claude's recent output with external sources when you push back on accuracy. Ad-hoc retrieval-augmented verification: the skill treats your skepticism as a signal that the previous answer needs evidence, not rephrasing.

## Commands

### `/ground`

Re-checks the most recent claim against authoritative sources (docs, source code, web search). Reports what holds up, what does not, and where the original answer needs correction.

## Auto-trigger

Activates on any doubt signal about factual correctness of Claude's own output:

- "dat klopt niet"
- "are you sure"
- "weet je dat zeker"
- explicit `/ground`
- any expression of skepticism about a recent claim

## Why

Defending an incorrect answer with more confident phrasing is the failure mode this skill exists to prevent. When the user expresses doubt, the right move is to verify, not to re-explain. `/ground` enforces that loop.

## Installation

```bash
/plugin install ground@leclause
```
