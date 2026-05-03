---
name: recap
user-invocable: true
description: Use when the user needs a status overview of the current session. Triggers on /recap, or when returning to a session after idle time, compaction, or repetitive background output.
effort: low
---

# Recap

Provide a structured overview of where we currently stand.

## Gathering sources

**Conversation context is always the primary source.** What has been discussed and decided in the current conversation determines the main narrative. Auto-loop files and git status are supplementary. Do not get distracted by files on disk that have nothing to do with the current work. An auto-loop file in OBSERVE with high watch_checks is background noise, not the main narrative.

Run these tool calls in parallel:

1. **Conversation context** - what has been discussed and decided in the current conversation
2. **Git status** - `git status` and `git diff --stat` for uncommitted changes, `git log --oneline -10` for recent activity
3. **Auto-loops** - `ls auto-loops/` in the project root. Only relevant when they are active (recent log entries, non-OBSERVE phase, or low watch_checks)
4. **Cron jobs** - CronList for running background tasks
5. **Tasks** - TaskList for running background processes

Not every source returns something. That is fine. Present what is there.

## Output format

Three sections, short and functional:

**Doing now**
The goal of the current work in 1-2 sentences. Not the technical details, but the story: why are we here, what are we trying to achieve.

**Status**
Where do we stand? Phase (if an auto-loop is active), what has been done, what is running in the background. Name the branch and any uncommitted changes if present.

**To do**
What is still open? What is waiting for input, what is running autonomously, what does the user need to decide. End with a concrete next-step proposal.

## Guidelines

- **Short and concrete.** No file listings, no technical enumerations. Functional description.
- **Honest about uncertainty.** If context was lost to compaction, say so. Do not guess.
- **Always actionable.** After reading, the user should know what the next concrete step is.
- **No summary of the summary.** Do not repeat what the user has just typed or seen. Focus on what is not visible from the repetitive output.
