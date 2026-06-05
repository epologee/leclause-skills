---
name: confer
user-invocable: true
description: Use when you want a peer second opinion on work just done or just discussed from another vendor's coding agent. Triggers on /intervision:confer, "let Codex check this", "second opinion from Codex", "confer with the other agent", "wat vindt codex hiervan", "laat codex meekijken". Hands the diff or the design to Codex via `codex exec`, surfaces its independent read, and confers back and forth.
effort: medium
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the intervision plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("intervision was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new intervision`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Confer

Intervision is peer consultation: equals looking at each other's work, not a supervisor looking down. Etymology says it plainly, `inter-` (between, among, together) against `super-` (from above). This skill brings a second coding agent in as that peer. You hand it the work just done or just discussed, it looks with fresh eyes and a different training, and the two of you confer. The value lives in the gap between two independent agents: where you and the peer disagree is exactly where the operator should look.

The peer here is Codex, reached through its `codex exec` command. It runs from the same repository, on its own login, with its own model behind it. That independence is the whole point; a peer trained the same way as you would only echo you.

## The peer has to be there

Before conferring, confirm the peer exists:

```bash
command -v codex >/dev/null 2>&1 || { echo "codex CLI not found; intervision needs a peer to confer with. Install and log in to Codex first."; }
```

If `codex` is missing, or `codex login status` shows you are not logged in, say so plainly and stop. There is no peer to confer with, and pretending otherwise wastes the operator's time. This is the one hard precondition.

## Three ways to confer

Pick by what just happened. All three run through `codex exec`.

**1. Check work just done, when there is a diff.** Codex's review path reads the repository's changes directly, so point it at the change set that matches "what we just did":

```bash
codex exec review --uncommitted     # staged, unstaged, and untracked work
codex exec review --base main       # everything on this branch against main
codex exec review --commit <sha>    # the changes in one commit
```

**2. Weigh a design just discussed, when there is no code yet.** Give Codex the context on stdin and keep it read-only so it reflects rather than edits. Use a quoted heredoc so nothing in the pasted text is expanded by the shell:

```bash
codex exec -s read-only - <<'PROMPT'
Peer review this plan before we build it.
<paste the design, the trade-off, the open question, including the parts we are unsure about>
PROMPT
```

**3. Confer back and forth.** A single answer is consultation; intervision is a conversation. Resume the same session to push on a point, defend your reasoning, or ask the peer to reconsider, again through a quoted heredoc:

```bash
codex exec resume --last - <<'PROMPT'
You flagged X as a race. The lock at <file:line> already serialises that path. Does that change your read?
PROMPT
```

Keep resuming until each disagreement is either resolved or sharpened into a question the operator should decide.

## How to confer well

The round-trip only earns its cost if the handoff is honest.

- **Give the peer the real work, not a summary you are proud of.** Point it at the actual diff, or paste the actual design with the shaky parts left in. A flattering summary buys a flattering review.
- **Read for the disagreement, not the agreement.** The peer agreeing is cheap and tells you little. The signal is where its independent read diverges from yours.
- **Stay a peer, not a deferrer.** A second agent is not an authority. When the peer is wrong, say so and confer back. When it is right, concede plainly. Equals, in both directions.
- **Keep the peer read-only by default.** The `review` path and `-s read-only` let it look without touching the tree. Let it propose; you and the operator decide what lands. Only widen the sandbox when the operator asks for it on purpose.
- **Never expand the handoff through the shell.** A pasted design or follow-up is arbitrary text and may contain `$(...)`, backticks, or quotes. Feed it on stdin through a quoted heredoc (`<<'PROMPT' ... PROMPT`) into `codex exec ... -`, never as a double-quoted argument, so the shell passes it to the peer verbatim instead of executing part of it.

## Bringing findings home

The peer's output is a pile of findings, not a to-do list. Each finding gets one honest fate:

- **Fix it** when it is real and the change earns its weight.
- **Skip it on cost versus value** when the fix would add more than it lifts, with a one-line reason.
- **Reject it** when it is hollow, with the evidence that makes it hollow.

Then surface the exchange to the operator: what the peer raised, what you did with each point, and where the two of you still disagree. Do not smooth the disagreements away. They are the most useful thing intervision produces, because they mark the spots neither agent can settle alone.
