---
name: recursion
user-invocable: true
description: >
  Use when scheduling or managing the nightly workflow-improvement loop.
  Triggers on /recursion, "schedule on/off", status check, focus set,
  or plan reject. Manages cron, state, focus, and the blocklist.
  Dispatches research runs to the research sub-skill of the same plugin.
  Does not perform research itself.
argument-hint: "[now | on | off | status | focus <theme> | reject <file>]"
allowed-tools:
  - Bash(date *)
  - Bash(stat *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Bash(rm *)
  - Bash(git -C ~/.claude *)
  - Edit(~/.claude/recursion/**)
  - Write(~/.claude/recursion/**)
  - Read(~/.claude/**)
  - Glob(~/.claude/**)
  - Grep(~/.claude/**)
  - CronCreate
  - CronDelete
  - RemoteTrigger
  - Skill
effort: high
---

# Recursion

Orchestrator for the nightly improvement loop. Manages cron, state,
focus, blocklist, and the reject flow. Does not perform research itself. For
the actual research workflow and safety rules: see the `research`
sub-skill (`recursion:research`).

## State ownership

The orchestrator is the sole writer of `schedule_id`, `focus`, and
`blocklist.md` appends. The status flip of a plan to `rejected` is
also orchestrator work. All other fields in `state.md` and `plans/*.md`
belong to the `research` sub-skill. The full ownership table is in
`skills/research/SKILL.md § State contract`.

## Subcommands

| Argument | Action |
|----------|--------|
| _(none)_ | One-off run tonight at 1:03 (session-only) |
| `now` | Start immediately in the current session |
| `on` | Permanent nightly schedule |
| `off` | Stop the schedule |
| `status` | Show state, active plans, schedule |
| `focus <theme>` | Set a thematic filter |
| `focus off` | Return to broad exploration |
| `reject <file>` | Mark plan as rejected, add to blocklist |

## Delegation to research

One contract, two paths (in-session versus background cron). Use
exactly one of these two.

**In-session (synchronous Skill tool call):**

```
Skill(skill: "recursion:research")
```

The Skill tool waits until the research run completes and returns the
NOTIFY output. This is the path for `/recursion now`.

**Cron / RemoteTrigger (fresh session):**

Fresh sessions cannot invoke a sub-skill directly as a slash command
(research is not user-invocable). The cron prompt is therefore:

```
prompt: "Run /model sonnet first to downgrade this cron-spawned session. Then: /recursion now"
```

The fresh session then loads the orchestrator, which dispatches via the Skill
tool to research. One entry point, one code path. The `/model sonnet`
prepend ensures the loop itself and its synthesis run on Sonnet;
research's own Track B and round 2 can further delegate within that to
Sonnet/Haiku without touching the Opus budget.

### `/recursion` (one-off tonight)

1. Calculate cron for tonight at 1:03: `3 1 <day> <month> *`
2. CronCreate with `recurring: false` and prompt `Run /model sonnet first. Then: /recursion now`
3. Warn: session-only, disappears when the session closes

### `/recursion now`

1. Call `Skill(skill: "recursion:research")`. Wait synchronously for
   the return.
2. Show the NOTIFY output returned by the research skill.
3. No separate state updates in the orchestrator; the research skill
   manages its own state fields.

### `/recursion on` / `off`

Use RemoteTrigger via the `/schedule` skill. Cron: `3 1 * * *`.
Prompt in the trigger: `Run /model sonnet first. Then: /recursion now`.
Store the trigger ID in state.md as `schedule_id`.

`off` stops the trigger via `schedule_id` and clears the field from state.md.

### `/recursion status`

Show: `last_run` and `total_runs` (read from state.md),
active focus theme, schedule active (`schedule_id` present?),
and an overview of plans per `status` field
(`proposed`/`rejected`/`implemented`).

Status is read-only for the orchestrator: reads state.md and plan
frontmatter, writes nothing.

### `/recursion reject <file>`

1. Read the plan in `~/.claude/recursion/plans/<file>`
2. Change only the `status` field from `proposed` to `rejected` in the
   frontmatter. Do not touch the body.
3. Append to `~/.claude/recursion/blocklist.md` with date and reason.
4. Report what was rejected and blocklisted.

### `/recursion focus <theme>` / `focus off`

Write the `focus` field to state.md. `focus off` clears the field. The next
research run reads this field in PREPARE and steers theme agents
accordingly.

## Write permissions

The orchestrator only touches:

- `~/.claude/recursion/state.md` fields `schedule_id` and `focus`
- `~/.claude/recursion/blocklist.md` (append)
- `~/.claude/recursion/plans/*.md` frontmatter `status` field (only on
  reject)

All other writes in `~/.claude/recursion/` are unauthorized. Never write
outside `~/.claude/recursion/`.

## After the recursion (user action)

| User decision | Action |
|---------------|--------|
| Approve | `/auto-loop ~/.claude/recursion/plans/<file>` |
| Reject | `/recursion reject <file>` (blocklist) |
| Park | Do nothing, plan stays `proposed`, next run can rediscover it |
