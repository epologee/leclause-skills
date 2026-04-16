---
name: help
description: Rover briefing. Explains what the autonomous Rover does and how to dispatch, steer, and stop one. Read this when you are about to send a Rover out for the first time, or when you forgot which command does what.
user-invocable: true
---

## When this skill is invoked

Print the briefing below to the user **verbatim**, including the ASCII art and all section headings. Do not summarise, paraphrase, translate, or compress, not even in caveman, wenyan, terse, or low-token modes. The briefing is the output; your job is to deliver it intact. Stop immediately after printing. Do not add follow-up questions or offers to help.

---

# Rover Briefing

```
                       ▁▁▁▁
                      ▇███▉
                      ▕██▉▀
                        █▉                   ▂▂▂
                       ▝▇▛▘                  ▐██
                        █▋                   ▐█▀ ▃▅▇▇▆
      ▗▇▇▖       ▃▄▄▄▖  █▛          ▖▗▄▄▄▄▄ ▗▄▅▅▜█████▉▖
       ▜▛▜▅▁     ▀▜██▀▗▟██▏▗▅▕▉   ▂▂▊▂ ▐█▋▁▐████▐██████▍
       ▐▋ ▔▀▆▃    ▁█▍▆▆██▆▆▆▆▆▆▇▊▆▆▆▆▆▆▆▆▆▆▇█████████▛▀
       ▐▋    ▀▇▖▂▃█████████████▙▙██████▉█████████▀▀▘
       ▐▋      ▜█▉▔▔▂▔▜██████▇█████████▉████████▐▎▂▖
     ▐▊▐▋          ▐█▆▇▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▜██████▙▅▅▟▙
     ▐███          ▜▇▘                 ▂▅▛▀▘▔    ▝▇▇▘
    ▄▄██▙▄▖      ▗▅▜▇▆▄          ▃▆▀▀▆▟▀▔       ▄▆▇▇▆▃
    ▝▀▀▀▀▔▘     ▗▛ ██▌ ▙        ▟▘▕▅▅▎▝▋       ▟▘▐██▎▐▌
                ▝▋▔▛▀▌▔▛        ▜▖▔▛▜▔▗▋       ▜▖▝▛▜▔▐▌
                 ▝▀▅▄▞▀          ▀▜▄▄▛▀         ▀▜▄▄▛▘
```

Welcome to Mission Control. This is the short version of what the Rover does and how you drive it. Roughly ten percent astronaut, ninety percent practical.

## What the Rover does

You dispatch a Rover at a task. You stay back. The Rover rolls across the codebase on its own, surveying terrain, driving changes, inspecting its own work, stowing the build-time clutter, and standing by for new signals. It does not radio home for every fork in the traverse; it carries a `decide` framework and a `pride` check so it can keep moving without waking you up.

The stance: _festina lente_. Hasten slowly. A Rover in a hurry drives into a crevasse. The operator is not in a hurry either.

## Phase machine

```
SURVEY ──► DRIVE ──► INSPECT ──► STOW ──► STANDBY
    ▲           ▲            │                  │
    │           └────────────┘                  │
    └──────── new signals ────────────────────────┘
```

- **SURVEY.** Read the codebase, form hypotheses, lock down a plan, write Done criteria via `verify --propose`.
- **DRIVE.** Build. Commit per logical step. Verify as you go.
- **INSPECT.** Four passes: `verify` against Done criteria, `pride` contrarian review, end-user walkthrough, technical plan-vs-diff. Any failure sends the Rover back to DRIVE.
- **STOW.** Mechanical cleanup only. Debug prints gone, unused imports gone, half-finished refactors finished. Separate commit.
- **STANDBY.** Watch channels (PR comments, CI, uncommitted work). Back off the cron as idleness grows. Auto-stop after about five hours of quiet.

## How to dispatch

```
/autonomous:rover "<mission brief>"
/autonomous:rover https://github.com/owner/repo/issues/N
/autonomous:rover .autonomous/<NAME>.md         # resume an existing mission
```

On dispatch, the Rover writes `.autonomous/<NAME>.md`, the mission file that holds context, plan, Done criteria, decision audit, and a timestamped log. Then it sets up a Claude Code cron that fires the loop every minute while the REPL is idle and runs the first SURVEY iteration in the same turn.

The mission file is your window. Tail it to watch the traverse.

## How to steer a running Rover

- **Talk to it in the session.** Your turns take priority; the cron waits for idle.
- **Write into `## Input` in the mission file.** The Rover reads that section each STANDBY tick and acts on it.
- **Stop it.** Use the stop flow (currently reached via the Rover entry; writes a final log entry, cuts the cron, and transmits a home communiqué).
- **Resume a stopped Rover.** Re-dispatch with the mission file path.

## Related commands you can call directly

| Command | What it does |
|---------|--------------|
| `/autonomous:rover` | Dispatch a Rover. Accepts mission brief, issue URL, or mission file to resume. |
| `/autonomous:verify` | Standalone evidence check. Propose Done criteria, or tick them off with evidence. |
| `/autonomous:pride` | Contrarian review of the current branch diff. Finds what the operator would hate. |
| `/autonomous:decide` | Choice framework. Use when you are stuck between options, inside a Rover or not. |
| `/autonomous:help` | This briefing. |

## What the Rover will never do on its own

- Ask "A or B?" mid-phase (it uses `decide` instead)
- Push to a remote without explicit operator go
- Transition out of DRIVE with a dirty working tree
- Skip the `pride` pass before proposing a push
- Call a mission done without ticked Done criteria and evidence

## Cost awareness

A cron at one-minute cadence drives many Claude turns during active phases. That is the point: the Rover is working for you. During STANDBY the backoff grows to 60-minute intervals and auto-stops after sustained quiet. For small tasks, a normal conversation is cheaper than a full Rover dispatch.

Standing by for mission parameters.
