# autonomous

Dispatch a rover at a task. You stay back, the rover works in the field. The distance means it has to decide locally, so the plugin ships a decide framework, a contrarian pride check, and an evidence-discipline verify pass. The rover only reports done when the mission is solid.

No hard dependencies on personal or team skills. Optional integrations (notifier, reviewbot, commit-splitter) are user-named at invocation and only used when installed.

## User-invocable skills

### `/autonomous:rover [issue-URL | loop-file-path | free-form text]`

Entry point. Accepts a GitHub issue URL, a loop file path to resume, or free-form mission text. Writes `.autonomous/<NAME>.md` (the loop file) and starts a `CronCreate` job that re-enters the conversation each minute while the REPL is idle.

### `/autonomous:resume <loop-file-path>`

Resume a stopped or expired loop. Reads the file, restores the cron via `cron`, summarizes current state, kicks off the next iteration.

### `/autonomous:stop [loop-file-path]`

Cleanly stop a running loop. Deletes the cron, writes a final log entry, produces a recap.

### `/autonomous:pride [git-range | uncommitted]`

Spawns a contrarian agent that reviews the current diff for what the user would notice but the rover missed. Auto-triggered before any push or PR-ready transition. Also invocable directly.

### `/autonomous:verify [--propose <loop-file> | <loop-file> | free text]`

Evidence discipline. With `--propose`, writes Done criteria into the loop file at the end of ANALYZE. Default mode ticks each criterion with evidence at the end of REVIEW.

## Internal skills (loaded by the rover)

- **`cron`**: scheduling machine. CronCreate, CronDelete, exponential backoff, auto-stop after sustained idleness, restoration after session restart.
- **`decide`**: decision framework. Loaded when the loop faces a choice and would otherwise ask the user.

## Phase machine

```
ANALYZE -> IMPLEMENT -> REVIEW -> STOW -> OBSERVE
```

The loop is autonomous. It does not ask questions mid-phase. When it hits a choice it invokes `decide`. Before any push or PR-ready transition it invokes `pride`. Pushes themselves are never autonomous: the user must say "push" or equivalent.

## Loop file

Lives in `.autonomous/<NAME>.md` at the git root. Holds context, plan, Done criteria, decision audit trail, and a timestamped log. Tail it to watch progress.

## Cost awareness

A cron at one-minute cadence drives many Claude turns. During active phases that is the point. During OBSERVE the backoff progresses to 60-minute intervals and auto-stops after roughly 5 hours of sustained idleness. For small tasks consider whether an ordinary conversation is cheaper.

## Installation

```bash
/plugin install autonomous@leclause
```
