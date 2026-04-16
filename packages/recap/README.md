# recap

Structured status overview of the current session: what we are doing, where we are, what is next. Useful when returning to a session after idle time, after compaction, or after a long stretch of repetitive background output where the thread becomes hard to follow.

## Commands

### `/recap`

Reads the recent conversation, the current branch, and any open files, then produces a short status:

- **Doing now:** the active task in one or two sentences
- **Where we are:** progress markers (commits made, tests run, files touched)
- **Next:** the immediate next action

## Auto-trigger

Activates on:

- explicit `/recap`
- returning to a session after idle time
- conversation compaction events
- long bursts of repetitive background output

## Installation

```bash
/plugin install recap@leclause
```
