---
name: stop
description: Cleanly stop a running autonomous loop. Deletes the cron, writes a final log entry, and produces a recap of what happened. Invocable as /autonomous:stop with an optional loop file path.
user-invocable: true
argument-hint: "[loop-file-path]"
---

# Autonomy Stop

End a loop on purpose, with a recap.

## When to use

- The work is done and the user is ready to review
- The loop is in a broken state (wrong branch, wrong scope, wrong file) and restarting cleanly is easier than fixing
- The user wants the loop off

## What it does

1. Locate the loop file. If an argument is given, use it. If not, list `.autonomous/*.md` candidates in the conversation and ask which to stop. This is the one place where asking is correct: stop is a user-invoked destructive action, and the user is present.
2. Read `cron_job_id` from the file. Invoke `cron` via the Skill tool to `CronDelete` that id.
3. Set `cron_job_id: stopped` in the loop file.
4. Append a final log entry with a timestamp from `date +%H:%M`: `[HH:MM] Stopped by user. Phase at stop: <PHASE>.`
5. Produce a recap to the conversation:
   - Goal (from Context section)
   - Phase at stop
   - Commits produced during the loop: compare the current branch against its fork point. Determine the fork point with `git merge-base <current> origin/<default>` where default is resolved via `git symbolic-ref refs/remotes/origin/HEAD`. If no remote HEAD is set, skip the commit list with a note, rather than guessing.
   - Any uncommitted work (`git status --short`)
   - Any open PR
   - The path to the loop file for future reference
6. If `notify_on_done` is set in the loop file, check installation via the `has_skill` helper. If installed, invoke it with the recap. If missing, log a loud line: `[HH:MM] Stop: notify_on_done=<X> is not installed, skipping notification.`

## What it does not do

- Does not delete the loop file. The file is history.
- Does not push, merge, or clean up commits. Those require explicit instructions.
- Does not restart the loop. Use `/autonomous:resume` for that.

## After stop

The cron is gone. The loop file stays. Any future `/autonomous:resume <file>` will bring it back with a fresh cron.
