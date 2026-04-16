---
name: resume
description: Resume a stopped or expired autonomous loop. Reads the loop file, restores the cron via cron, summarizes current state, and kicks off the next iteration. Invocable as /autonomous:resume with a loop file path.
user-invocable: true
argument-hint: "<loop-file-path>"
---

# Autonomy Resume

Revive a loop that was paused, auto-stopped, or lost its cron because the Claude session ended.

## When to use

- Session restarted and an old loop file in `auto-loops/` should continue
- Loop auto-stopped after ten idle polls but new activity is expected (a review just came in, a test just ran)
- Context was compacted and the loop file shows work mid-flight

## What it does

1. Read the loop file at the argument path. If no argument, list candidates from `auto-loops/*.md` and ask which to resume.
2. Check liveness of the recorded `cron_job_id`. Use `CronList` if available via the Skill/Tool interface. A `cron_job_id` of `stopped` or `failed` is a durable terminal marker and means the loop needs a fresh cron regardless of file age.
3. If the loop file records a branch (under `## Context` or similar), verify the current branch matches or offer to switch. If no branch was recorded, continue on the current branch.
4. Invoke `cron` via the Skill tool to restore: `CronCreate` at the interval matching `watch_checks`, write the new `cron_job_id` into the file.
5. Summarize the loop's current state to the conversation:
   - Phase
   - Last log entries (tail 10 lines)
   - Any uncommitted changes in the working tree
   - Any open PR associated with the branch
   - Anything in the `## Input` section waiting to be read
6. Acquire the lock (see `cron` concurrency section) before running one iteration of the current phase. This prevents the fresh cron from firing the same iteration in parallel. Release the lock when done.

## Detecting a compacted session

After a context compaction, the conversation summary usually contains phase words (ANALYZE, IMPLEMENT, REVIEW, OBSERVE). If you see those and a loop file, prefer `resume` over manual takeover.

## What it does not do

- Does not modify the loop's Plan or Context. Those are the loop's memory.
- Does not push anything. Resume is local.
- Does not take over work the cron was going to do. Hand it back to the loop.

## After resume

The cron is live and will drive from here. If the user is present, they can add notes to the `## Input` section or let the cron tick by itself.
