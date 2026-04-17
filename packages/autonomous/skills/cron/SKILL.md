---
name: cron
description: Uplink cadence machine for the rover. Handles CronCreate, CronDelete, exponential backoff when the field goes quiet, auto-stop after sustained standby, and cron restoration after a session restart. Not user-invocable; loaded by rover, wake, and stop.
user-invocable: false
---

# Autonomy Cron

The cron machine behind an autonomous loop. Its job: keep the loop firing at an appropriate cadence, slow down when nothing is happening, and restart itself cleanly after a session restart.

## Why a separate skill

Cron logic is mechanical and repetitive. Inlining it in the rover's code blurs the core flow. Separating it means:

- `rover` reads like an intent document, not a scheduler
- `wake` reuses the exact same restore logic
- Backoff and auto-stop policy lives in one place

## Setup (new loop)

At rover start, `rover` has already written the loop file. Your job:

1. Compute cron expression. Active phase = `* * * * *`. STANDBY with `watch_checks >= 1` uses backoff.
2. `CronCreate` with the project's standard prompt (see below)
3. Write the returned job id to `cron_job_id` field in the loop file

### Standard cron prompt

```
Read the file `.autonomous/<FILENAME>.md` in this project. Check the Phase.
Follow the Instructions section for the current phase. Add a timestamped
entry to the Log when you take action (run `date +%H:%M` first, never guess).
If nothing changed, do nothing.
```

Replace `<FILENAME>` with the actual file.

## Backoff table

| watch_checks | Interval | Cron expression |
|--------------|----------|-----------------|
| 0 | 1 min | `* * * * *` |
| 1 | 2 min | via `relative-cron 2` |
| 2 | 5 min | via `relative-cron 5` |
| 3 | 10 min | via `relative-cron 10` |
| 4 | 20 min | via `relative-cron 20` |
| 5 | 30 min | via `relative-cron 30` |
| 6+ | 60 min | via `relative-cron 60` |

`relative-cron` is shipped in `bin/` of this plugin. It handles a quirk of cron expressions: `*/N` is not "fire every N minutes from now" but "fire on every minute divisible by N". So `*/20` fires at `:00`, `:20`, `:40`, regardless of when you set it up. If you write `*/20` at `:19`, the next fire is in 1 minute, not 20. For idle backoff where the goal is "wait N minutes before the next check," short intervals (≤ 10) are fine with `*/N` but longer intervals need an explicit target minute: `<current + N> * * * *`. `relative-cron` returns the right form for each case.

**Locating the binary.** SKILL.md files are markdown, not scripts, so `$0` resolves to whatever shell launched Bash (usually `-zsh` or `/bin/bash`). Do not use `$(dirname "$0")`. Resolve via the plugin cache layout instead:

```bash
# Plugins install under ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/
RC=$(compgen -G "$HOME/.claude/plugins/cache/*/autonomous/*/bin/relative-cron" | sort -V | tail -1)
if [ -z "$RC" ] || [ ! -x "$RC" ]; then
  echo "cron: relative-cron binary not found, using */N fallback" >&2
  CRON="*/${minutes} * * * *"
else
  CRON=$("$RC" "$minutes")
fi
```

The `sort -V | tail -1` picks the highest installed version when multiple plugin versions coexist in the cache.

## When to change the cron

**Nothing to do (STANDBY idle tick):**
1. Increment `watch_checks` in the loop file
2. If the new value crosses a backoff threshold, `CronDelete` old job, `CronCreate` with new interval, update `cron_job_id`
3. Log a one-line tick with timestamp (`date +%H:%M`) including the new `watch_checks` value and the current interval. Silent ticks hide whether the cron is actually running.

**New input or phase becomes active:**
1. Reset `watch_checks: 0`
2. `CronDelete` old job, `CronCreate` with `* * * * *`, update `cron_job_id`
3. Log the reset with reason

**Auto-stop (hard cap):**
When `watch_checks` reaches 10, the loop is effectively idle. Total idle time to reach this uses the backoff schedule at each step:

| watch_checks | Interval waited at this step |
|--------------|------------------------------|
| 0 to 1 | 1 min |
| 1 to 2 | 2 min |
| 2 to 3 | 5 min |
| 3 to 4 | 10 min |
| 4 to 5 | 20 min |
| 5 to 6 | 30 min |
| 6 to 7 | 60 min |
| 7 to 8 | 60 min |
| 8 to 9 | 60 min |
| 9 to 10 | 60 min |

Sum: 1 + 2 + 5 + 10 + 20 + 30 + 60 × 4 = 308 minutes, about 5 hours.

1. `CronDelete` the current `cron_job_id`
2. Set `cron_job_id: stopped` in the loop file (durable terminal marker)
3. Log "stopped after 10 idle polls"
4. If `notify_on_done` is set and `has_skill` returns true for it, invoke it with a brief end-of-loop summary; otherwise log the summary only

## Restore after session restart

Cron jobs are session-scoped. A new Claude session means the old job id in the loop file is dead. Before doing any other work, restore the cron.

1. Read the loop file, note `watch_checks`
2. Compute cron expression from the backoff table
3. `CronCreate` with that interval and the standard prompt
4. Update `cron_job_id` in the loop file
5. Now continue with whatever the phase requires

If the loop's phase is STANDBY and `watch_checks >= 10`, the loop was already auto-stopped. Do not restore. Log a note that the loop was found in terminal state.

## Stopping on demand

Called by `stop` or when an DRIVE, INSPECT, or STOW phase finishes cleanly with no STANDBY channels to watch:

1. `CronDelete` with the current `cron_job_id`
2. Set `cron_job_id: stopped` in the loop file
3. Log the stop

The loop file itself is never deleted. It is history.

## Edge cases

**Cron fires during active session.** The REPL is busy with user interaction. The cron waits for idle, which is fine. No action needed from this skill.

**CronCreate fails.** Session might be in a weird state. Retry once. If still failing:

1. Log a loud error line to the loop file: `[HH:MM] CronCreate failed after retry. Loop has no cron. User must drive manually or run /autonomous:wake.`
2. If `notify_on_done` is configured and its skill is installed, invoke it with the failure.
3. Leave `cron_job_id: failed` in the loop file as a durable marker.

Do not silently proceed.

**Concurrency: threshold-cross race.** Two cron iterations can fire closely if a late tick and a threshold-cross tick overlap. Both read the same `watch_checks`, both decide to reset, both issue CronDelete/CronCreate. Guard with a file-based lock when doing the read-modify-write on `watch_checks`:

```bash
LOOP="$1"
LOCK="${LOOP}.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "cron: another iteration holds the lock, skipping" >&2
  exit 0
fi
# read watch_checks, compute new interval, edit file, CronDelete, CronCreate
```

On systems without `flock` (macOS by default), fall back to `mkdir` lock or atomic `ln -s` as a sentinel. The lock file name tracks the loop file, so multiple loops do not block each other.

**Multiple loops active.** Each loop file has its own `cron_job_id`. They do not conflict. Do not try to share a cron across loops.

**Session ended → cron is dead regardless of age.** Do not rely on file `stat` to infer cron liveness. Use `CronList` via the Skill or ToolSearch path and check for the id. A 30-minute-old loop file from a closed session has a dead cron just as surely as a 3-day-old one.

## Reference: relative-cron

Shipped at `packages/autonomous/bin/relative-cron`. Usage:

```bash
relative-cron 20     # -> "47 * * * *" (when now is :27)
relative-cron 5      # -> "*/5 * * * *"
relative-cron 60     # -> exact fire minute one hour from now
```

Rules: short intervals (`<= 10`) use `*/N`, longer intervals compute exact minute to avoid the `*/N` alignment trap.
