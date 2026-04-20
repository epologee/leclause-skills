---
name: stop
description: End a rover mission on purpose. Cuts the cron, writes a final log entry, and transmits a communiqué home covering mission, ship state, hard parts, review verdicts, and what the operator can pick up next. Not user-invocable directly; reached via the rover entry point.
user-invocable: false
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
5. Produce a communiqué to the conversation. The communiqué is itself a rover artefact, so run `pride` on the drafted text before transmitting it (log the pride findings in the loop file, fix them or explicitly accept them with a written reason, then send the final version). Not a data dump: a rover's report back home. Enough story for the operator to understand what happened without re-reading the log. Six sections, one paragraph each, in this order:

   **Mission.** Restate the goal from the Context section in one sentence. What was the rover sent out to do.

   **What shipped.** The end state in plain prose. Number of commits, the headline outcome, where the work now lives (branch, files of note). Compare the current branch against its fork point to list commits: `git merge-base <current> origin/<default>` where default is resolved via `git symbolic-ref refs/remotes/origin/HEAD`. If no remote HEAD is set, skip the commit list with a note rather than guessing. Also note any uncommitted work from `git status --short` and any open PR.

   **Choices and hard parts.** The story of the run. Walk the Decision Audit Trail entries and the Log pivots together: which calls had real trade-offs, where the rover changed course (for example, a `Transition back to SURVEY` line after user input), what assumption broke and had to be revised. One or two sentences per meaningful moment, not a transcript.

   **Review results.** What the `verify` and `pride` passes actually caught. Quote the criteria count and the pride-finding count. Name the commits that addressed each batch of findings. If additional review passes ran (end-user walkthrough, technical plan-vs-diff), summarise their verdicts.

   **How to try it.** Concrete next actions the operator can run to see the result for themselves. File paths to open, commands to execute, URLs to visit. Pull straight from the Done criteria's evidence lines where possible; those were designed to be verifiable.

   **Not done.** Mandatory, even when it is empty. Every Done criterion that is not ticked with evidence, every pride finding that was rejected with a reason, every side-observation that was deferred to a follow-up: each gets a bullet here with one sentence of context and one sentence naming the fate (operator-accepted reject, scope-moved-to-issue-N, explicit deferral with cause). No soft collectives like "small nits" or "polish items"; each remaining item is a concrete bullet the operator can count. If the section is genuinely empty, write the literal sentence `Nothing remains. Every Done criterion is ticked, every pride finding resolved.` and only that sentence.

   **What is next for you.** The human-only actions: push or merge waiting for go, follow-up tickets, manual smoke-tests the rover could not perform. If nothing is left, say so explicitly. Close with the loop file path and the phase at stop so the operator can find the full log if they want it.

The banned closing language from `pride` applies to this communiqué verbatim. Phrases like "mostly done", "roughly complete", "corners cut", "good enough for now", "kleine puntjes over", "polish for later", "almost there" are rejected by the pride pass on the drafted communiqué; rewrite the prose, do not smuggle the feeling past the banned-word list with a synonym. If the communiqué would honestly read that way, the rover is not in a state to stop; transition back to DRIVE and close each item first.
6. If `notify_on_done` is set in the loop file, check installation via the `has_skill` helper. If installed, invoke it with the recap. If missing, log a loud line: `[HH:MM] Stop: notify_on_done=<X> is not installed, skipping notification.`

## What it does not do

- Does not delete the loop file. The file is history.
- Does not push, merge, or clean up commits. Those require explicit instructions.
- Does not restart the loop. Use `/autonomous:wake` for that.

## After stop

The cron is gone. The loop file stays. Any future `/autonomous:wake <file>` will bring it back with a fresh cron.
