---
name: rover
description: Dispatch a rover at a task. You stay back, the rover works in the field. The distance means it has to decide autonomously, the decide framework picks the path, the pride skill checks the work, and the rover only reports done when the mission is solid. Accepts a GitHub issue URL, a loop file path to resume, or free-form text describing the mission.
user-invocable: true
argument-hint: "[issue-URL | loop-file-path | free-form text]"
---

# Autonomous Rover

Dispatch a rover at a task. You stay back, the rover works in the field. Round-tripping every question takes too long, so it decides locally. The rover cycles through ANALYZE, IMPLEMENT, REVIEW, STOW, OBSERVE on its own and reports back when the mission is solid.

The metaphor is load-bearing. Every time the rover catches itself wanting to ask "A or B?", it remembers the distance: asking costs time in both directions, and the mission does not wait. So it uses `decide` instead. Every time it catches itself wanting to ship work without checking, it remembers nobody in the field has reviewed it yet: so it uses `pride` first.

## What you see in the first 60 seconds

You type `/autonomous:rover "build the settings page"`. In response:

1. Claude writes `auto-loops/.gitignore` and `auto-loops/BUILD-SETTINGS-PAGE.md` (the loop file holds the full plan and progress).
2. Claude starts a `CronCreate` job that will re-enter this conversation every minute while the REPL is idle, carrying a prompt that tells Claude to read the loop file and act on the current phase.
3. Claude immediately runs the first ANALYZE iteration in the same turn, so you see work happening right away. Reading files, searching the codebase, forming a plan.
4. Between your turns, the cron ticks. Every tick is Claude reading the loop file and either doing the next chunk of work or logging "nothing to do."

The loop file is your window. `auto-loops/BUILD-SETTINGS-PAGE.md` gets a timestamped log line on every action. Tail it to watch progress.

## How to steer a running loop

- You can keep chatting in the same session. Your messages take priority; the cron waits for the REPL to be idle.
- To inject guidance without interrupting mid-work: open the loop file and add text under `## Input`. The loop reads this section each OBSERVE iteration and acts on it.
- To stop: type `/autonomous:stop`. The loop cancels its cron and gives you a recap.
- To resume after you closed Claude and came back: type `/autonomous:resume auto-loops/<NAME>.md`. Crons are session-scoped; they do not survive restarts. Resume recreates a fresh cron from the file's state.

## What you are building

A markdown file in `auto-loops/` that holds context, phase, plan, decision audit, and log. A Claude Code cron job that fires the loop prompt every minute while the REPL is idle. A phase machine (ANALYZE, IMPLEMENT, REVIEW, STOW, OBSERVE) that each cron tick advances.

Phases and transitions:

```
ANALYZE ──► IMPLEMENT ──► REVIEW ──► STOW ──► OBSERVE
    ▲           ▲            │                  │
    │           └────────────┘                  │
    └──────── new issues ────────────────────────┘
```

The loop is autonomous. It does not ask questions mid-phase. When it hits a choice, it invokes `decide`. Before any push or PR-ready transition it invokes `pride` to catch what it missed. No human is required to keep it moving, but you can intervene via the `## Input` section or the `/autonomous:stop` and `/autonomous:resume` commands at any time.

## Cost awareness

A cron at one-minute cadence drives many Claude turns. During active ANALYZE/IMPLEMENT/REVIEW/STOW phases that is the point: the loop is working on your behalf. During OBSERVE the backoff progresses to 60-minute intervals and auto-stops after roughly 5 hours of sustained idleness. If your task is small, consider whether `/autonomous:rover` is right for it, or whether an ordinary conversation is cheaper.

## Verification

The rover invokes `verify --propose` at the end of ANALYZE to write Done criteria into the loop file, and `verify` (default mode) at the end of REVIEW to tick each criterion with evidence. The details of what evidence counts, how to gather it, and why proxies do not qualify live in the `verify` skill. Treat it as the rover's evidence discipline: without Done criteria the mission has no endpoint, without evidence the mission is not finished.

## Setup order is not negotiable

The first tool calls after this skill loads are:

1. `Write auto-loops/.gitignore` with content `*` (always, even if the dir already exists; the Write tool creates parent dirs)
2. `Write auto-loops/<NAME>.md` with the template below, fully populated
3. Invoke `cron` via the Skill tool to `CronCreate` and write the job id back
4. Run the first ANALYZE iteration directly in this same turn

No exploration first. No "let me check the codebase." No skills loaded before the cron is live. The whole point is to get the loop running. Exploration happens inside the loop.

The first iteration races with the cron's period. This is safe because cron only fires when the REPL is idle, and the first iteration blocks idle. But: tune the initial cron to `* * * * *` (every minute) regardless of expected ANALYZE duration. If ANALYZE takes 20 minutes, that is fine; the cron will not fire until you yield.

## Arguments

| Argument | Meaning |
|----------|---------|
| (none) | Use the current conversation as context. Distill to 2-3 sentences. |
| `https://github.com/.../issues/N` | Run `gh issue view`, use title + body as context. |
| `auto-loops/<name>.md` | Resume. Delegate to `resume`. |
| Free-form text | Use the text directly as context. |

Free-form text may also describe optional integrations. Parse phrases like:

- "when you are done, send me a message via /afk" -> `notify_on_done: /afk`
- "use /review-bot-party for reviews" -> `reviewbot: /review-bot-party`
- "split commits with /commit-all-the-things" -> `commit_splitter: /commit-all-the-things`

For each parsed integration, verify the skill or binary exists before recording it. Use the `has_skill` helper from `decide`. When a user-mentioned integration is not installed, do not silently skip: log a loud line to the loop file so the user notices on any later read. Example: `[HH:MM] Setup: user mentioned /afk but it is not installed. Integration disabled.`

## Writing the loop file

Choose a name: ALL-CAPS, hyphens, no spaces. Describe the goal, not the mechanism. Examples: `FIX-STALE-CACHE.md`, `INVESTIGATE-SLOW-QUERIES.md`, `BUILD-AUTH-PAGE.md`.

### Canonical names

- **Skill references** inside a loop file use the bare skill directory name: `rover`, `cron`, `decide`, `pride`, `verify`, `resume`, `stop`. Never the slash form (`/autonomous:rover`).
- **Optional integration values** use the slash form users type: `/afk`, `/review-bot-party`, `/commit-all-the-things`. That is what `has_skill` and Skill-tool invocations match on.

Template:

````markdown
# <NAME>

cron_job_id: <filled after CronCreate>
watch_checks: 0     # consecutive OBSERVE ticks with nothing to do, drives idle backoff

## Integrations

notify_on_done: <skill name or empty>
reviewbot: <skill name or empty>
commit_splitter: <skill name or empty>

## Context

<2 to 5 paragraphs. What is the task. Why. What is known. What is in scope and out. Any constraints from the user. Any optional integrations and how to use them.>

## Phase

ANALYZE

## Plan

_To be written during ANALYZE phase._

## Done criteria

_To be written by `verify --propose` at the end of ANALYZE. Each criterion must be concrete, observable, and binary. REVIEW ticks each one with evidence before the mission is considered finished._

## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale |
|---|-------|----------|----------------|-----------|-----------|

## Input

_Write new input here during a running loop. The loop reads this section each OBSERVE iteration and removes it after processing._

## Log

```
```

## Instructions

You are an autonomous loop. Follow the phase machine below. The user is not available for decisions, use `decide` when you face a choice. Use `pride` before any push or PR-ready transition.

### Phases

**ANALYZE**
Search the codebase. Read relevant files, tests, logs, errors. Form hypotheses. Verify with concrete evidence: a failing test, a trace, a grep result. Write findings to the Log. When the plan is concrete and verifiable, fill the Plan section, invoke `verify --propose` to generate Done criteria, then transition to IMPLEMENT.

Scope must match the goal. "Manage X" means at least create + view in the first iteration. "Read-only first, CRUD later" is scope reduction in disguise. If the goal is management, the first iteration is management.

**IMPLEMENT**
Follow the project conventions. Read project CLAUDE.md and user CLAUDE.md for branch strategy (trunk vs feature-branch), commit style, push policy. Default to the most recent pattern in the repo, not the most common.

Quality over speed. No duct tape, no hacks. Structural solutions. Commit per logical step. Do not transition out of IMPLEMENT with uncommitted changes.

During IMPLEMENT, verify each significant change as you go (run the code, screenshot the UI, query the state). Do not batch verification to the end. See the `verify` skill for tactics.

When the feature does what the Done criteria say it should, transition to REVIEW.

**REVIEW**
Four passes. Each one can send the rover back to IMPLEMENT with a specific target. REVIEW only completes when all four are clean.

1. **Verify pass.** Invoke `verify` against the loop file's Done criteria. Any criterion without evidence, or with failed evidence, sends the rover back to IMPLEMENT. REVIEW only continues once every criterion is either met with evidence or explicitly marked unverified with a reason the operator can accept.

2. **Pride pass.** Invoke `pride` on the diff. A contrarian subagent looks for what the user would hate: duplicate fixes, type smells, ugly helpers, defensive filtering, race conditions. Findings go back to IMPLEMENT until pride is clean.

3. **End-user pass.** Spawn an agent with only the stated goal and the application domain. Not the code, not the plan. The agent uses the feature as a user and reports confusion, missing feedback, edge cases, dead ends. Default to fixing, not deferring.

4. **Technical pass.** Spawn an agent that reviews the diff against the plan. Does it match the goal? Odd jumps? Unnecessary complexity? Missed alternatives? Before the technical review, if the project has tech-specific skills matching the changed file types, load them.

When all four passes are clean, transition to STOW.

**STOW**
Final housekeeping before handoff. Mars rovers literally stow their robotic arm and instruments before driving on or going into uplink; the software equivalent is removing what got used during build and review but should not ship.

STOW is strictly mechanical. No new logic, no new behavior, no architectural changes. Just cleaning the workspace.

Walk the full diff (use `git diff` against the base branch and `git diff HEAD` for any uncommitted work) and remove or fix:

- Debug print/log statements added during build
- Commented-out code, including "TODO: maybe later" comments without an issue link
- Unused imports, helpers, variables, parameters; check the function signatures of anything you touched
- Premature abstractions: a base class with one subclass, a config option with one value, a helper called once. Inline them.
- Half-finished refactors: pick one direction and commit, do not leave the codebase mid-rename or mid-extraction
- Temp files, test fixtures, scaffolding that was useful during build or review but is not part of the feature
- TODO comments: convert to a tracked issue, fix now, or delete
- Comments that explain *what* the code does (the code already does that) rather than *why* it does it

Commit the cleanup as a separate logical commit so the diff history shows build, review fixes, and housekeeping as distinct steps.

If STOW uncovers something that requires a logic change (for example, a "premature abstraction" that turns out to be load-bearing), that is a sign the review phases missed something. Go back to IMPLEMENT, then through REVIEW again. Do not make logic changes inside STOW.

When the diff is clean and the cleanup commit has landed, transition to OBSERVE.

If the project has a PR workflow (detect: has remote, has `.github/`, or explicitly mentioned in CLAUDE.md), create a Draft PR. Otherwise, commit directly, no PR. If `reviewbot` is configured, invoke it after the PR is up.

**OBSERVE**
Check all input channels. This means tool calls, not assumptions. If there is nothing to check (no PR, no remote), OBSERVE does not need cron. Stop the cron and let the session drive.

When a PR exists, minimum checks per iteration:
- `git status --short` (uncommitted work from the session)
- PR comments and reviews (via `gh api`)
- CI status (via `gh pr checks`)

New findings from OBSERVE go back to ANALYZE (not IMPLEMENT, and not queued for the user). New input is new information: understand it before acting on it. Iteratively downgrading to a fix-first approach has a track record of missing the real cause.

When no new activity, increment `watch_checks` and invoke `cron` for backoff. Auto-stop after `watch_checks` reaches 10. The full backoff schedule and total idle time (about 5 hours) live in `cron`; do not duplicate the numbers here.

### Decisions

Any time you catch yourself about to ask the user "A or B?": invoke `decide`. It will classify, apply principles, run research skills if helpful, and return a path. It writes the decision to the audit trail.

Never ask mid-phase. The invocation of `/autonomous:rover` is the user's blanket approval for autonomous decisions.

### Commits and pushes

Commits: autonomous. The user approved them by starting the loop. Commit per logical step with a descriptive message. Follow the project's commit conventions.

Pushes: never autonomous. Even inside a loop, pushing to a remote requires explicit user approval ("push", "ship", or equivalent). When a push is pending, log it, continue with whatever can be done locally, and surface the ready-to-push state to the user at the next OBSERVE check.

### Timestamps

Every log line needs a timestamp from `date +%H:%M`. Never guess based on "it was just 09:41 so now it is 09:42." Run `date`.
````

## Starting the cron

Invoke `cron` via the Skill tool. That skill's setup flow runs `CronCreate`, writes the job id back to the loop file's `cron_job_id` field, and sets the initial interval to `* * * * *`.

"Delegate" throughout these skills means: call the Skill tool with the target skill name. Not inline instructions, not shelling out. The Skill tool invocation.

## The first iteration

Cron fires on REPL idle. You are not idle, you just finished setup. Run the ANALYZE iteration yourself, in the same turn:

1. Read the loop file you just wrote
2. Execute the ANALYZE instructions
3. Log each meaningful action with a timestamp from `date +%H:%M`
4. When ANALYZE completes, transition to IMPLEMENT and start

The cron is the safety net for everything after you stop driving, not the starter.

## Branch strategy

Loops do not all need branches. A loop that produces no committed code does not need a branch. A loop that will commit code:

- Trunk-based projects (most personal repos, user CLAUDE.md says "direct on main"): commit on current branch
- Feature-branch projects: create a branch named after the goal (no slashes, no prefixes, describe the goal)

The loop makes this call during the transition to IMPLEMENT, not during setup.

## Optional integrations

A loop runs without any of these. They are conveniences the user plugs in at invocation time. Only use if detected at setup:

- **notify_on_done.** After auto-stop or explicit stop, if a notifier skill is configured and installed, invoke it with a brief summary. Examples commonly used: `/afk` (personal Telegram), a team's Slack-posting skill, or any user-provided notifier. The plugin itself ships none of these.
- **reviewbot.** After creating a PR, if a review-bot skill is configured and installed, invoke it. Examples: a personal `/review-bot-party`, a team's review orchestrator.
- **commit_splitter.** If the loop produced uncommitted changes spanning multiple concerns and a commit-splitter skill is configured and installed, invoke it before the push. Example: `/commit-all-the-things`.

If a user mentions an integration at setup that turns out not to be installed, log a loud line at that time (see "Parsing" above). Do not fail silently when running.

These examples are illustrations, not defaults. An external user reading this skill should not assume any of those names exist. The contract is "any skill the user has installed and named in their invocation," not "these specific slash commands."

## Project conventions

The loop reads both user CLAUDE.md and project CLAUDE.md before any code change. It adapts to:

- Trunk vs feature-branch
- Commit style
- Push approval policy
- Test requirements
- Language conventions

These are project-specific and not hardcoded in this skill.

## What the loop should never do

- Ask the user "A or B?" mid-phase
- Push without explicit user approval
- Transition out of IMPLEMENT with a dirty working tree
- Skip `pride` before proposing a push
- Assume `/afk`, `/touche`, `/retake`, `/review-bot-party`, `/screenshots`, or any team/personal skill exists
- Write loop files anywhere other than `auto-loops/` in the git root

## Resuming or stopping

A running loop is resumed with `/autonomous:resume <file>` and stopped with `/autonomous:stop <file>`. The loop itself does not handle these; they are separate skills. See `resume` and `stop`.
