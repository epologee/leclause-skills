# Plan Template

Canonical schema for plan files in `~/.claude/recursion/plans/`. Single source of truth, shared by `recursion` (reads `status` on reject) and `research` (writes new plans).

## Filename

`YYYY-MM-DD-short-description.md`

Example: `2026-03-25-hook-test-coverage-check.md`

## Frontmatter fields

| Field | Possible values | Writer |
|-------|-----------------|--------|
| `status` | `proposed`, `rejected`, `implemented` | `research` (proposed on write), `recursion` (rejected on /recursion reject) |
| `date` | `YYYY-MM-DD` | `research` |
| `category` | `skill`, `claude-md`, `hook`, `setting`, `structural` | `research` |
| `impact` | `high`, `medium`, `low` | `research` |
| `confidence` | `robust`, `probable`, `fragile` | `research` |

## Body template

```markdown
# [Title: what changes]

status: proposed
date: YYYY-MM-DD
category: [skill | claude-md | hook | setting | structural]
impact: [high | medium | low]
confidence: [robust | probable | fragile]

## What

Concrete description. Which files change? What is the
end result? Be specific: "Add iOS-specific test guidance
to testing-philosophy" is a plan, "improve testing" is not.

## Why

The most important section. Concrete scenarios, frequency of the
problem, quantification where possible. If the why does not
convince, the plan is not strong enough.

## Source

URLs to blog posts, issues, discussions. Or internal observation
with a reference to a concrete file or line. Multiple sources
strengthen the plan. One source is the minimum.

## Who else does this

Concrete examples with URLs. Per reference: who (name/handle),
what (their implementation), and where (link to repo, blog, or
discussion). No vague references ("some developers do this"),
only verifiable references. Minimum 1, preferably 2-3.
If truly nobody does this: describe explicitly why this is a
gap that has not yet been filled, not an idea nobody needs.

## Auto-loop context

### Goal
[1-2 sentences: what the auto-loop must achieve]

### Files that change
- `path/to/file`: [what changes]

### Steps
1. [concrete step with expected result]
2. ...

### Verification
- [how to verify it works]

### Scope boundary
- [what does NOT fall within this plan]
- [when is the auto-loop DONE]
```

## Quality requirements

Every plan must satisfy:

1. **Atomic**: implementable in one auto-loop session
2. **Self-contained**: auto-loop context contains everything needed to start
3. **Convincing**: why section leaves no doubt
4. **Verifiable**: concrete check that it works
5. **Bounded**: scope boundary prevents creep

Improvements that are too large: split into multiple plans with ordering.

## Status transitions

```
(new) --research writes--> proposed
proposed --recursion reject--> rejected (plus blocklist addition)
proposed --user implements via /auto-loop--> implemented
```

`research` writes only `proposed`. The status transitions `rejected` and `implemented` belong to the orchestrator and the user respectively.
