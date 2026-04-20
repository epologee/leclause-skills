---
name: pride
description: Pride check. Spawns a contrarian agent that reviews a rover artefact with a skeptical eye and surfaces what the operator would hate but the rover missed. Hard gate, runs on every artefact the rover produces (code, docs, prose, research briefs, media, communiqués), not just pushes. Also invocable directly as /autonomous:pride against the current branch diff.
user-invocable: true
argument-hint: "[git-range | uncommitted]"
---

# Autonomy Pride

Are you proud of this work?

Not "do the tests pass." Not "did CI go green." Proud. As in: you would show this to a thoughtful colleague without flinching. Every file. Every line.

Most of the time, the answer without this check is an unthinking "yes" because CI is green. The pride check forces a harder look.

## Why this matters inside an autonomous loop

In an ordinary workflow, code review and "sleeping on it" catch the pride-level issues: the one dumb helper, the four duplicate fixes, the `|| true` that swallows a real error. An autonomous loop has none of those. The loop commits, pushes, moves on. Without a pride check, the loop's INSPECT phase validates the happy path against CI and declares success. The rest ships unreviewed.

The pride check injects an independent skeptic before the loop transitions to its "done" states. If the loop is good at what it does, the pride check usually finds something real. When it finds nothing, it has to explain what it examined and why nothing was flagged. Vague "looks good" is rejected.

## When to run

**Auto-triggered by `rover`.** Canonical triggers:

1. Before any rover artefact leaves the rover. "Artefact" is read broadly: diffs, commits, PRs, pushes, documentation, READMEs, research briefs, plans, summaries, letters, emails, slide decks, video scripts, generated images, audio, slash-command responses, communiqués, anything the rover produced that a human will read. Pride reviews all of it, not only code.
2. As the second pass in INSPECT, right after `verify`, so pride findings feed the DRIVE-fix loop while the artefact is still fresh. Pride runs before STOW so its findings can be fixed as real logic or content changes; STOW is strictly mechanical cleanup and cannot fix what pride flags.

(If a loop runs INSPECT, fixes things, then ships more work, run pride once per batch. Every new batch of artefact before handoff gets its own pride pass.)

**There is no exemption for research-only missions.** A loop whose output is a research brief, a plan, an analysis document, or any other prose deliverable gets the same pride pass as a loop that ships code. The artefact IS the diff-equivalent. See "Gathering the artefact" below for how to feed a prose-only deliverable to the contrarian subagent.

**Manually via `/autonomous:pride`:**
- `/autonomous:pride` reviews the uncommitted changes plus commits on the current branch not yet on the default branch
- `/autonomous:pride <ref>` reviews a specific commit range, for example `main..HEAD` or `HEAD~3..HEAD`
- `/autonomous:pride uncommitted` reviews only the uncommitted diff

## How

Spawn a subagent with no prior context. Give it the artefact, the loop's Context section if one exists, and the matching brief below.

For code artefacts, give the subagent the diff plus this brief:

> You are reviewing recent code changes with a skeptical eye. You have not seen the implementation decisions, the plan, or the reasoning. Ignore sunk cost.
>
> For every changed file, find:
>
> 1. **Duplicate fixes.** Is the same change applied in four different places because of a repeated rubocop/lint warning? That is a smell. The underlying rule is either wrong or the abstraction is missing.
> 2. **Type smells.** Are there `casecmp?`, string comparisons, or `.to_s` calls where the source returns a different type (symbol, number)? These often compile but silently misbehave.
> 3. **Ugly helpers.** Is there a method whose job is to paper over an awkward interface? Name it, show the better alternative.
> 4. **Defensive filtering.** Are there guards that skip "unexpected" values? That often hides the real bug upstream.
> 5. **Shell noise.** Shell commands of the form `X && Y || echo "..."` are swallowing errors. Any `|| true` on a non-idempotent command is suspect.
> 6. **Race conditions.** New async code, new background jobs, new state mutations: is there a window where two callers step on each other?
> 7. **Stale documentation.** README, comments, or docstrings that describe behavior that is no longer accurate after this change.
> 8. **The question the user would ask.** Read the diff as if you are the user who asked for this work. What would make them say "why did you..."?
> 9. **Effort-and-scope reflexes.** The rover has a documented reflex to skip work on effort or scope grounds. Look for the *pattern*, not only the literal phrases: any sentence that (a) acknowledges the work is not complete AND (b) suggests completion is optional, deferrable, or someone else's problem. That covers literal banned phrases in both English and Dutch ("mostly done" / "grotendeels", "roughly complete", "corners cut" / "hier en daar corners", "good enough for now", "small issues remain" / "kleine puntjes over", "polish for later", "almost there", "this would take too long" / "dit kost te veel tijd", "too big for this pass" / "te groot voor deze mission", "out of scope because it would take too long", "warrants a separate mission") and every paraphrase of them ("approximately landed", "substantially resolved", "the bulk is in", "a handful of edge cases are queued", "tracked in backlog for continuity", "de minimis", "fine for a 0.9"). It also covers the structural escape: a "Follow-ups", "Next up", or "Backlog" section whose bullets are rover-originated deferrals rather than operator-chosen scope, regardless of how diplomatic the wording is.
>
> For each finding: file:line, what you see, why it is a problem, and the concrete fix.
>
> Be blunt. A finding is better than a compliment. If there is nothing to find, say so explicitly, but try hard first.

For prose artefacts (research briefs, plans, analysis documents, letters, summaries, PR descriptions, communiqués), give the subagent the artefact plus this brief:

> You are reviewing a written deliverable with a skeptical eye. You have not seen the mission, the sources, or the reasoning. Ignore sunk cost. The author cannot defend themselves; your job is to find what the operator would push back on.
>
> For the whole document, find:
>
> 1. **Confidence laundering.** Hedged evidence presented as firm conclusion. Phrases like "likely," "appears to," "suggests that" stacked up into a confident claim. Flag each jump from hedge to certainty.
> 2. **Unsourced claims.** Specific facts, numbers, names, dates, quotes, or URLs without a citation or a verifiable source. Training-data invention is a real risk: product names, conference tracks, speaker lists, locations, dates.
> 3. **Over-claims.** Statements that go further than the evidence supports. A single example presented as a pattern. A correlation presented as a cause. A possibility presented as a plan.
> 4. **Ungrounded references.** URLs that were not actually fetched, repos that were not actually read, studies that were not actually cited, people who may not exist. Flag every external reference that could not be verified.
> 5. **Missing caveats.** Limitations, counter-evidence, alternatives that the author knew about but did not mention. What would a hostile reviewer say is absent?
> 6. **Scope creep in prose.** Sections that drifted beyond the stated mission. Recommendations that the author was not asked for. Conclusions that assume facts not in evidence.
> 7. **The question the user would ask.** Read the document as if you are the user who commissioned it. What would make them say "where did you get this?" or "did you actually check?" or "why did you include this?"
> 8. **Effort-and-scope reflexes.** The rover has a documented reflex to skip work on effort or scope grounds and paper over it with prose that sounds measured. Look for the *pattern*, not only the literal phrases: any sentence that (a) acknowledges the work is not complete AND (b) suggests completion is optional, deferrable, or someone else's problem. That covers literal banned phrases in both English and Dutch ("mostly done" / "grotendeels", "roughly complete", "corners cut" / "hier en daar corners", "good enough for now", "small issues remain" / "kleine puntjes over", "polish for later", "almost there", "this would take too long" / "dit kost te veel tijd", "too big for this pass" / "te groot voor deze mission", "out of scope because it would take too long", "warrants a separate mission") and every paraphrase of them ("approximately landed", "substantially resolved", "the bulk is in", "a handful of edge cases are queued", "tracked in backlog for continuity", "de minimis", "fine for a 0.9"). It also covers the structural escape: a "Follow-ups", "Next up", or "Backlog" section whose bullets are rover-originated deferrals rather than operator-chosen scope, regardless of how diplomatic the wording is.
>
> For each finding: the exact phrase or passage, what you see, why it is a problem, and the concrete fix (strike it, rewrite it, add a source, add a caveat).
>
> Be blunt. A finding is better than a compliment. If there is nothing to find, say so explicitly, but try hard first.

## Gathering the artefact

Pride runs on whatever the rover produced. Start by naming the artefact:

1. **Code artefact.** A diff exists. Use the git range logic below to collect it.
2. **Prose artefact with no committed diff.** A research brief, plan, analysis, letter, or summary that lives as a file in the repo, in `.autonomous/<NAME>.md`, or as a drafted response in the loop file. Feed the full text of that file or section to the subagent as the review target.
3. **Mixed.** The rover produced both code and prose. Run pride twice with the appropriate brief for each, or give the subagent both payloads with a clear separator and both briefs.
4. **Generated media (images, audio, video, slides).** Describe the artefact in words (filename, purpose, summary of contents, any claims embedded in captions or voice-over), feed that description to the subagent with the prose brief, and run pride on the source text of any embedded claims.

If the rover cannot identify an artefact to hand to pride, there is nothing to hand off either. The pride gate is not satisfied by absence of output; it is only satisfied by a reviewed artefact.

### Gathering the diff

The skill argument (`$1` as the skill tool passes it) determines the range:

```bash
ARG="${1:-}"

case "$ARG" in
  "" )
    # No arg: "branch so far" plus any uncommitted work.
    DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    if [ -z "$DEFAULT" ]; then
      echo "pride: cannot determine default branch (remote HEAD not set). Run 'git remote set-head origin -a' or invoke /autonomous:pride with an explicit range." >&2
      exit 1
    fi
    RANGE="origin/${DEFAULT}..HEAD"
    INCLUDE_UNCOMMITTED=true
    ;;
  uncommitted )
    RANGE=""
    INCLUDE_UNCOMMITTED=true
    ;;
  *..* | *...* )
    RANGE="$ARG"
    INCLUDE_UNCOMMITTED=false
    ;;
  * )
    RANGE="${ARG}..HEAD"
    INCLUDE_UNCOMMITTED=false
    ;;
esac

DIFF=""
if [ -n "$RANGE" ]; then
  DIFF=$(git diff "$RANGE")
fi
if [ "$INCLUDE_UNCOMMITTED" = true ]; then
  DIFF="${DIFF}$(git diff HEAD)"
fi
```

`*...*` matches the symmetric-difference form (`main...HEAD`) which git treats differently from `main..HEAD`. Passing it through to git is correct.

Pass the collected diff to the subagent. Large diffs: `git diff --stat "$RANGE"` first, pick hot files, truncate per-file reads to 300 lines with a note, rather than dumping a 5000-line blob.

## What to do with findings

**Inside a running loop (auto-triggered):**

1. Write findings to the loop file's `## Log` section under a `[HH:MM] Pride check findings:` header
2. Set Phase back to DRIVE if there is anything actionable
3. Do NOT forward findings to the operator mid-loop. Fix them first.

**Invoked manually (`/autonomous:pride`):**

1. Print findings to the conversation
2. Ask the operator if they want you to fix them now
3. No auto-fix without user confirmation when run manually

### Reject-ratio gate

Every finding is either **fixed** in a follow-up DRIVE cycle or **rejected** with a written reason that names a concrete fact (not a feeling). "Bewuste keuze" without pointing at where that choice was made is not a reason. "Out of scope" without a sentence explaining which scope-boundary applies is not a reason.

Count the findings in the last pride pass. Two triggers for the second-pass gate, either is enough:

- **Ratio trigger:** the rover is about to reject more than 30% of the findings (strict greater-than, so 3 of 10 passes, 4 of 10 does not).
- **Small-N trigger:** the pass had two or fewer findings and the rover is about to reject any of them. Rejecting one of two is 50%, rejecting one of one is 100%; both are too suspect to resolve without a second reader.

When either trigger fires, stop and run pride a second time with a different subagent and a stricter brief ("the author keeps rejecting findings; tell me which rejects are hollow and which ones are real"), then reconcile the two reports before moving on. Log both runs in the loop file.

A reject is only final after the second-run subagent independently agrees (concrete-evidence-of-non-issue, per `rover`'s category-2 definition), or after the operator acknowledges the reject in `## Input` (operator-accept, same definition). The rover does not get to retire a finding unilaterally.

### Banned closing language

The following phrases are evidence the rover is handing off half-finished work. Any of them in an artefact, a communiqué, a commit message, or a mid-loop status line sends the rover back to DRIVE, no exceptions:

- "mostly works", "mostly done", "largely addressed", "grotendeels"
- "roughly done", "roughly complete", "a rough pass"
- "corners cut", "some corners", "hier en daar corners"
- "good enough for now", "good enough for v1", "good enough for this pass"
- "nits remaining", "kleine puntjes over", "small issues remain"
- "will follow up later", "later polish", "polish-for-later"
- "not quite there", "not fully done", "almost done"

The pattern these share: an acknowledgement that the work is not complete, paired with a suggestion that completion is optional. Pride rejects that combination. Either the work is complete or it is not; if it is not, every remaining item becomes a tracked finding with one of two fates (fix now, or explicit operator-accepted reject) before anything ships.

## What counts as "nothing found"

Genuinely clean work exists. But "I checked and it looks fine" is not a review. If the subagent returns "nothing found," require it to list:

- What it examined (files, patterns, specific risk areas)
- Why nothing was flagged (specific, not generic)

One sentence minimum per risk category. "No race conditions because the new code runs inside a single database transaction" beats "no race conditions found."

If the subagent returns a vague "looks good," reject and re-run with stronger prompting.

## Anti-patterns

| Smell | What it actually means |
|-------|------------------------|
| "The tests pass" | Proxy for correctness, not review |
| "Copilot already reviewed" | Bot review is a first pass, not the pride check |
| "I already thought about this" | You thought about the happy path |
| "The PR description covers it" | Descriptions sell, they do not review |
| "This is good enough for v1" | Haste projection. See `decide` |
| "There is no diff, so nothing to review" | The artefact is the review target, not the diff |
| "It is just research, pride does not apply" | Research briefs are where confidence laundering lives. Apply it harder. |
| "I will run pride after the push" | Pride runs before. After is too late. |
| "The operator will catch it on review" | That is exactly the review the rover exists to stand in for |

## Token awareness

This skill spawns a subagent with a diff payload. For large branches, prefer `git diff --stat` first and then targeted diff reads. Do not dump a 5000-line diff into the subagent; summarize and focus.
