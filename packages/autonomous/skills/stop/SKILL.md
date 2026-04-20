---
name: stop
description: End a rover mission on purpose. Cuts the cron, writes a final log entry, and transmits a mission report home: a length-scaled narrative of the traverse, a qualitative conclusion, a listing of what did not land, and the concrete operator-only next actions. Not user-invocable directly; reached via the rover entry point.
user-invocable: false
---

# Autonomy Stop

End a loop on purpose, with a recap.

## When to use

- The work is done and the operator is ready to review
- The loop is in a broken state (wrong branch, wrong scope, wrong file) and restarting cleanly is easier than fixing
- The operator wants the loop off

## What it does

1. Locate the loop file. If an argument is given, use it. If not, list `.autonomous/*.md` candidates in the conversation and ask which to stop. This is the one place where asking is correct: stop is an operator-invoked destructive action, and the operator is present.
2. Read `cron_job_id` from the file. Invoke `cron` via the Skill tool to `CronDelete` that id.
3. Set `cron_job_id: stopped` in the loop file.
4. Append a final log entry with a timestamp from `date +%H:%M`: `[HH:MM] Stopped by user. Phase at stop: <PHASE>.`
5. Produce a communiqué to the conversation. The communiqué is itself a rover artefact, so run `pride` on the drafted text before transmitting it (log the pride findings in the loop file, fix them or explicitly accept them with a written reason, then send the final version).

   Not a data dump, not a form with six bullet-headers. A **mission report** written as prose: the operator comes back to the TUI and wants to read a story of the traverse, not grep through section titles. The goal is that after reading, the operator knows where the rover went, what it found, what it changed along the way, and what the next move is, without having to re-read the loop file or ask "are you proud of this?"

   ### Length matches the mission

   Compute mission duration from the Log: first timestamped entry to the stop timestamp. Scale the communiqué by that duration, with the shape of the story preserved in each size:

   | Mission duration | Traverse prose | Conclusion | Next actions |
   |------------------|----------------|------------|--------------|
   | `< 2 hours` | at least 1 paragraph per landmark | 1 paragraph | Bulleted |
   | `2h ≤ duration < 12h` | at least 1 paragraph per landmark, plus a scene-setting opener | 1 to 2 paragraphs | Bulleted |
   | `≥ 12 hours` | at least 1 paragraph per landmark, sub-landmarks for multi-beat ones | 2 to 3 paragraphs | Bulleted |

   The shape rule is "at least one paragraph per landmark" at every duration; the table sets the expected minimum context beyond that. A short mission with a long communiqué is padding; a long mission that genuinely had three landmark beats does not need ten paragraphs of prose invented to fill a range.

   ### Shape of the communiqué

   **Traverse (prose).** The journey in chronological order, told as landmarks and what the rover did at each: the initial read of the terrain during SURVEY, the decision points that the Decision Audit Trail captured, the pivots where an assumption broke and the rover re-planned (mark these explicitly, they are the most interesting parts of the story), the INSPECT passes and what they caught, the STOW cleanup. Decision entries from the audit trail are woven into the prose as supporting detail, not listed separately. Pride findings and their fates belong in-line: "the review surfaced X, which turned out to be Y, and was fixed in commit Z" reads better than a dedicated review-results section. Pull concrete artefacts in where they carry the story: commit SHAs for landmark changes, file paths for the hardest edits, command outputs that changed the rover's mind. Avoid the temptation to summarise; summaries are what the operator is trying to avoid by reading this at all.

   **Qualitative conclusion (prose).** One or more paragraphs, length-scaled, that give the operator a read on how the mission actually went. What is the rover confident about, and what is it less confident about and why? Where was the work easy, where was it hard, and did the final form address the hard parts cleanly or did compromises land? Was the original Dispatch the right framing, in hindsight? This is the section where the operator finds "am I proud of this?" answered in advance; the rover writes an honest self-assessment here so the operator does not have to extract one.

   `pride`'s category 8 (effort-and-scope reflex) applies to the conclusion paragraph verbatim. Any wording that the reflex-pattern detector flags means the rover is not in a state to stop. Transition back to DRIVE, close each item, then re-draft the communiqué.

   **Not done.** Mandatory, even when it is empty. Every Done criterion that is not ticked with evidence, every pride finding that was rejected with a reason, every side-observation that was deferred to a follow-up: each gets a bullet here with one sentence of context and one sentence naming the fate (operator-accepted reject, scope-moved-to-issue-N, explicit deferral with cause). No soft collectives like "small nits" or "polish items"; each remaining item is a concrete bullet the operator can count. If the section is genuinely empty, write the literal sentence `Nothing remains. Every Done criterion is ticked, every pride finding resolved.` and only that sentence.

   **Next actions for you.** A bulleted list of concrete operator moves, each a one-liner. These are **only** actions the rover cannot perform itself: push, merge, deploy, notify a stakeholder, review a specific design trade-off where operator judgement was required, pick between two options that the rover explicitly flagged as User Challenge. **Never** "try it out", "verify it works", "test the feature", "check that the UI looks right", "see if it does what you wanted". The rover has already done verification during INSPECT; asking the operator to redo that work duplicates effort and contradicts the Done-criteria evidence. If the rover could not verify something and wants the operator to do it, it belongs in **Not done** as an explicit unverified criterion, not in next actions dressed as a casual smoke-test request.

   Close the communiqué with the loop file path and the phase at stop, on its own line, so the operator can find the full log if they want it.
6. If `notify_on_done` is set in the loop file, check installation via the `has_skill` helper. If installed, invoke it with the recap. If missing, log a loud line: `[HH:MM] Stop: notify_on_done=<X> is not installed, skipping notification.`

## What it does not do

- Does not delete the loop file. The file is history.
- Does not push, merge, or clean up commits. Those require explicit instructions.
- Does not restart the loop. Use `/autonomous:wake` for that.

## After stop

The cron is gone. The loop file stays. Any future `/autonomous:wake <file>` will bring it back with a fresh cron.
