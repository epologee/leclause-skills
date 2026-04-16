# inspiratie

Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. Forces external perspectives before committing to one path.

Dutch-language skill, but works against any topic.

## Commands

### `/inspiratie`

Searches online for how others solve the current problem, summarizes the patterns found, and contrasts them with the approach under consideration. Returns concrete pointers (libraries, articles, repositories) rather than generic advice.

## Auto-trigger

Activates on questions like:

- "hoe doen anderen dit"
- "wat bestaat er al"
- "is hier een library voor"
- explicit research requests
- unfamiliar domains where the conversation would otherwise rely on training data

## Why

The reflex to bolt together a bespoke solution is strong. `/inspiratie` interrupts that by insisting on a quick external survey first. Often the right answer is a well-tested library, not 50 lines of custom code.

## Installation

```bash
/plugin install inspiratie@leclause
```
