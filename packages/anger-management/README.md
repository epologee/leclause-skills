# anger-management

A swear jar that pays you back in workflow improvements.

When a session grates and you have no appetite to be constructive about it
right then, vent. Each venting command logs the moment as a tiny friction
paper-cut instead of demanding an immediate fix. Later, `/anger-management` reads the
pile back, finds the patterns, and hands the worst offenders to
self-improvement.

This is the deliberately low-effort front door to friction reduction: the
beerput of self-improvement. The capture costs you one word; the constructive
work happens on your terms, in aggregate, never in the heat of the moment.

## Why it works this way

The split between cheap in-the-moment capture and a later prioritisation pass
is how teams already run this. Stripe wired "bad day" buttons into every
engineering tool so frustration could be logged frictionlessly, then a
separate team mined the pile for low-hanging fruit. Friction logging and
paper-cut collectors follow the same shape. Repeated vents against the same
project or theme are the rage-tap signal: a real friction point, not a one-off
bad moment. This plugin is that pattern, scaled down to a single agent
session.

## Commands

| Command | What it does |
|---------|--------------|
| `/fuck`, `/shit`, `/crap`, `/wtf`, `/bullshit`, `/damn` | Vent. Logs one cheap line and moves on. No apology, no analysis, no scope change. |
| `/anger-management` | Read the log back, surface recurring frictions, offer to route the worst to `/self-improvement`. |

The vocabulary is deliberately gender-neutral and non-discriminatory:
scatological and generic-sexual words, nothing that punches at a group.

## The log

Append-only JSONL at a deterministic, marketplace-shared location:

```
~/.claude/var/leclause/anger-management/friction.jsonl
```

Each line: `{ "ts", "word", "cwd", "git", "note" }`. The note is a pointer of
at most a dozen words to whatever caused the friction, drawn from the
conversation. The log is yours; clear it by hand if you want a fresh start.

## How a vent is handled

1. The agent distils what grated into a short pointer and feeds it to
   `bin/anger-log <word>` on stdin (via a quoted heredoc, so the pointer is
   never interpreted by the shell even if it echoes hostile content).
2. The command's own `logged <word>: ...` line is the acknowledgement. The agent
   adds at most one terse line, then resumes. It does not launch self-improvement,
   apologise, or change scope. That is the whole point.
