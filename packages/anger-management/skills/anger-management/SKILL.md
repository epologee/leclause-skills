---
name: anger-management
user-invocable: true
description: Invoked as /anger-management. Reads back the friction paper-cut log, surfaces recurring patterns, and offers the worst to self-improvement; runs only when the operator types the command.
effort: low
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the anger-management plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("anger-management was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new anger-management`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Anger Management

The constructive other half of the venting commands. The venting commands
(`/fuck`, `/shit`, `/crap`, `/wtf`, `/bullshit`, `/damn`) are a zero-effort
capture gesture: when something about the session grates, the operator vents
one word and the moment is logged instead of derailing into a fix. This skill
is where that pile gets read back and turned into something useful, on the
operator's terms and not a second sooner.

## Where the log lives

Append-only JSONL at a deterministic, plugin-scoped location shared with the
rest of the leclause marketplace:

```
~/.claude/var/leclause/anger-management/friction.jsonl
```

Each line is one vent: `{ "ts", "word", "cwd", "git", "note" }`. The capture
side keeps every line cheap; the value is in the aggregate, not the single
entry.

## What to do

Read the log and report patterns. Keep it proportional to what is there.

1. Read the log at `~/.claude/var/leclause/anger-management/friction.jsonl`. The path is
   the contract; reach for whatever reader fits the session. No file or an empty
   file means nothing has been vented yet: say so, remind
   the operator that the vent commands (`/fuck`, `/shit`, `/crap`, `/wtf`,
   `/bullshit`, `/damn`) are what fill this log, and stop.

2. Surface the signal, not the noise:
   - **Clusters** are the strongest signal. Several vents close together in
     time, or repeated against the same `cwd`, the same `git` branch, or the
     same kind of `note`, are the rage-tap equivalent: a real friction point,
     not a one-off bad moment.
   - Group by what actually recurs (project, branch, theme of the notes).
     Count, do not transcribe. The operator wants "this keeps happening", not
     a diary read-back.
   - A lone vent with no companions is a bad moment, not a pattern. Note it
     exists, do not dwell.

3. Present the top recurring frictions as a short ranked list, worst first.
   For each: what it is, how often, and where it bites.

4. Offer, do not force, the constructive pass. For the top one or two
   patterns, propose handing them to `/self-improvement` so the friction
   turns into a CLAUDE.md rule, a skill, or a hook. The operator decides
   whether and when; venting was never a request to act, and reading the log
   is not either.

## Arguments

- No argument: full read-back and pattern report as above.
- `<text>`: treat as a filter (a word, a project name, a theme) and report
  only the matching slice of the log.

## Guidelines

- **Match the operator's language** for the report; this is operator-facing
  prose.
- **Proportional output.** Three vents get three lines. Do not inflate a thin
  log into a grand analysis.
- **No moralising.** The log is a beerput by design. Report what is in it
  plainly, no commentary on the swearing itself.
- The log is append-only and the operator owns it. If they want it cleared,
  point at the path; do not truncate it unprompted.
