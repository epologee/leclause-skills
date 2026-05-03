# recursion

Nightly workflow-improvement loop. The `/recursion` orchestrator manages schedule, state, focus, and the reject list. It dispatches research runs to an internal `research` sub-skill that runs the deep workflow producing atomic improvement plans.

The orchestrator does not perform research itself. The research machine does not execute the plans it produces. Separation is the point.

## Commands

### `/recursion [now | on | off | status | focus <theme> | reject <file>]`

| Argument | Effect |
|----------|--------|
| (none) | Status overview |
| `now` | Run a research iteration immediately |
| `on` | Schedule the nightly cron |
| `off` | Cancel the nightly cron |
| `status` | Current schedule, focus, blocklist |
| `focus <theme>` | Constrain the next iteration to a theme |
| `reject <file>` | Add a generated plan to the blocklist |

## Sub-skills (internal)

### `research`

Not user-invocable. Dispatched only by the orchestrator (via Skill tool) or by a scheduled trigger that calls this skill by name. Runs parallel Opus agents for friction analysis and external discovery, synthesizes findings across three rounds, and writes self-contained plan files.

## Output

Plans land in `~/.claude/recursion/plans/` as standalone markdown files. Each plan is small, atomic, and ready to execute in a separate session. The orchestrator keeps a state file so successive runs can build on or skip prior work.

## Installation

```bash
/plugin install recursion@leclause
```
