---
name: recap
user-invocable: true
description: Use when the user needs a status overview of the current session. Triggers on /recap, or when returning to a session after idle time, compaction, or repetitive background output.
effort: low
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the recap plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("recap was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new recap`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

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
What is still open? What is waiting for input, what is running autonomously, what does the user need to decide.

**Closing line (mandatory).** The recap MUST end with a single bolded sentence that names the next-action owner and the next action, in the form `**<owner>: <action>**`. Owner is one of: `operator` (user needs to do or say something), `claude` (Claude is working on it and will continue), `external` (waiting on CI, a deploy, a third party). Action is the concrete next step in 5 to 12 words. Examples: `**operator: zeg "ship" om de push naar main te triggeren.**`, `**claude: DRIVE op finding F3, ETA twee ticks.**`, `**external: CI run #4123 draait, geen actie van jou nodig.**`. Without this closing line the recap is incomplete; a vague "let me know" or a multi-sentence wrap-up defeats the point. The operator reads the closing line first and decides from there whether to scroll up for context.

## Guidelines

- **Match conversation language.** Recap is operator-facing prose; write in the language the operator is using in this conversation, not the language of the project files. A Dutch-speaking operator reading an English recap pays a translation tax for no benefit.
- **Short and concrete.** No file listings, no technical enumerations. Functional description.
- **Honest about uncertainty.** If context was lost to compaction, say so. Do not guess.
- **Always actionable.** After reading, the user should know what the next concrete step is.
- **No summary of the summary.** Do not repeat what the user has just typed or seen. Focus on what is not visible from the repetitive output.
