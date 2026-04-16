---
name: pride
description: Pride check. Spawns a contrarian agent that reviews the current work critically and finds what the user would notice but you missed. Auto-triggered by loop before any push or PR-ready transition. Also invocable directly as /autonomous:pride against the current branch diff.
user-invocable: true
argument-hint: "[git-range | uncommitted]"
---

# Autonomy Pride

Are you proud of this work?

Not "do the tests pass." Not "did CI go green." Proud. As in: you would show this to a thoughtful colleague without flinching. Every file. Every line.

Most of the time, the answer without this check is an unthinking "yes" because CI is green. The pride check forces a harder look.

## Why this matters inside an autonomous loop

In an ordinary workflow, code review and "sleeping on it" catch the pride-level issues: the one dumb helper, the four duplicate fixes, the `|| true` that swallows a real error. An autonomous loop has none of those. The loop commits, pushes, moves on. Without a pride check, the loop's REVIEW phase validates the happy path against CI and declares success. The rest ships unreviewed.

The pride check injects an independent skeptic before the loop transitions to its "done" states. If the loop is good at what it does, the pride check usually finds something real. When it finds nothing, it has to explain what it examined and why nothing was flagged. Vague "looks good" is rejected.

## When to run

**Auto-triggered by `rover`.** Canonical triggers:

1. Before a push, whether direct-to-trunk or PR-ready. This is the primary gate.
2. As the second pass in REVIEW, right after `verify`, so pride findings feed the IMPLEMENT-fix loop while the code is still fresh. Pride runs before STOW so its findings can be fixed as real logic changes; STOW is strictly mechanical cleanup and cannot fix what pride flags.

(These two are usually the same commit range. If a loop runs REVIEW, fixes things, then pushes, run pride once before REVIEW and once before the push if additional commits landed.)

**Manually via `/autonomous:pride`:**
- `/autonomous:pride` reviews the uncommitted changes plus commits on the current branch not yet on the default branch
- `/autonomous:pride <ref>` reviews a specific commit range, for example `main..HEAD` or `HEAD~3..HEAD`
- `/autonomous:pride uncommitted` reviews only the uncommitted diff

## How

Spawn a subagent with no prior context. Give it the diff, the loop's Context section if one exists, and this brief:

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
>
> For each finding: file:line, what you see, why it is a problem, and the concrete fix.
>
> Be blunt. A finding is better than a compliment. If there is nothing to find, say so explicitly, but try hard first.

## Gathering the diff

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
2. Set Phase back to IMPLEMENT if there is anything actionable
3. Do NOT forward findings to the user mid-loop. Fix them first.

**Invoked manually (`/autonomous:pride`):**

1. Print findings to the conversation
2. Ask the user if they want you to fix them now
3. No auto-fix without user confirmation when run manually

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

## Token awareness

This skill spawns a subagent with a diff payload. For large branches, prefer `git diff --stat` first and then targeted diff reads. Do not dump a 5000-line diff into the subagent; summarize and focus.
