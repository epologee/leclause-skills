---
name: do-that
description: Use ONLY when the operator types `/do-that` (or the fully-qualified `/dont-do-that:do-that`) with no extra arguments. Signals that the assistant just offered a recipe, instruction, or proposed action instead of executing it, and the operator wants the action performed now. Resolves the most recent proposal in the assistant's previous turn and runs it via the available tools (Bash, Edit, Write, browser, etc.). The proposal must be exactly one super-clear non-ambiguous action; if multiple distinct candidates exist in the previous turn, ask the operator to pick (A vs B) before running anything. Never guess.
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the dont-do-that plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("dont-do-that was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new dont-do-that`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# do-that

Sister to the `do-that` Stop guard in this plugin. The guard catches the reflex at write-time; this skill is the operator's one-keystroke correction at read-time.

## When this fires

The operator types `/do-that` (or `/dont-do-that:do-that`) with no further words after it. The trigger is the slash command itself; do not wait for additional context.

The operator is pointing at the **immediately preceding assistant turn**. In that turn you offered one of:

- a recipe ("je kunt dit checken door `bin/foo` te draaien", "you can verify this by running `npm test`"),
- an imperative instruction ("Run `bin/migrate`", "Voer `bundle exec rspec` uit"),
- a browser/terminal action ("open `http://localhost:3000` in je browser", "navigate to the dashboard"),
- a confirmation question that proposed a reversible action ("Wil je dat ik X doe?", "Zal ik Y opzetten?"),
- a multi-step plan presented as instructions for the operator to follow.

In every case the operator's `/do-that` means: stop offering, start executing.

## What to do

1. **Re-read the previous assistant turn and identify the action.** There must be exactly one super-clear, non-ambiguous concrete action (a single shell command, a single file edit, a single URL to open, a single multi-step procedure that obviously belongs together). If you cannot point at one specific thing the operator must mean, **stop and ask** (see "Disambiguate first" below). Do not guess. Do not pick the most likely one.
2. **Execute it.** Use the right tool: Bash for shell commands, Edit/Write for file changes, browser tools for URLs, the appropriate MCP for everything else. A multi-step procedure that was proposed as a single coherent unit (for example, "I'll run the migration, then restart the daemon, then tail the log") counts as one action and runs in the proposed order.
3. **Report results inline as you go.** When a step produces output the operator needs to see (test failures, diagnostic output, screenshots), surface it. When a step is silent (a file edit that succeeded, a daemon that restarted), say so in one line.
4. **Stop at the first real gate.** If the proposed action hits an inviolable gate from `~/.claude/CLAUDE.md` (push, merge to default, deploy, destructive git, external irreversible operation), stop there and ask. Reversible local actions (running a script, editing a file, restarting a local daemon, querying a DB) are not gates and do not require a check-in.
5. **End with a one-line outcome.** What ran, what it produced, what (if anything) is still pending. End with `🏁` when the proposed work is done, or `🚦` when you are waiting on an external go.

## Disambiguate first

`/do-that` is shorthand for a specific thing. If the previous turn contained more than one candidate action and they are not obviously the same coherent procedure, ask the operator which one before running anything. The operator chose to type two short words instead of naming the action; that is convenience, not blanket delegation. Asking once is cheap; running the wrong thing can cost the rest of the session.

The clarification template is short and specific. Always use the literal forms the operator can echo back:

> Bedoel je A (run `bin/foo`) of B (`bin/bar` + restart van de daemon)?

> Did you mean (A) running the migration on staging, or (B) the local rspec sweep?

Rules for the menu:
- **Two or three options max.** If you proposed more than three things, that is a sign the previous turn was a brainstorm, not a proposal; do nothing and ask the operator what they meant.
- **Each option is one line, with the concrete command or edit.** No explanation, no rationale, no "I'd recommend A". The operator picks; you do not advise.
- **Number or letter the options.** So the operator can reply "A" or "1" without retyping the command.
- **No fourth option labelled "iets anders".** If they wanted something else, they would not have typed `/do-that`. If they reply with something else, take that as the action and run it.

After the operator picks, execute that one action and report the result, exactly as in step 2-5 of "What to do".

## Anti-patterns

- **Asking what to do when the previous turn had exactly one proposal.** `/do-that` is the answer; running it is the response.
- **Offering the recipe again in different words.** That is the exact reflex this skill exists to break. If you find yourself typing "I will run `bin/foo`", stop and run it.
- **Picking the most likely action from an ambiguous list and running it silently.** When in doubt, ask. The cost of a one-line "Bedoel je A of B?" is far below the cost of running the wrong thing on a system the operator cares about.
- **Padding the disambiguation prompt with explanation.** Two or three options, one line each, no commentary. The operator already saw the previous turn; they do not need it summarised.

## Edge cases

- **No clear proposal in the previous turn.** Rare but possible (the operator misfired the command, or the proposal was buried in a tool result rather than an assistant message). Say so in one line and ask what they meant. Do not invent an action.
- **Multiple unrelated proposals in the previous turn.** Disambiguate per the section above. Do not run them all and do not pick.
- **The previous turn proposed something genuinely irreversible** (push, deploy, force-push, merge to default). `/do-that` does not lift those gates; they live above this skill. Surface the gate, ask for the explicit go.
- **The previous proposal was a teaching answer the operator asked for** (they typed "how do I X manually?", you wrote a recipe with `Instructie:` per the do-that guard). `/do-that` overrides that framing: the operator now wants execution, not teaching, on whichever single recipe was proposed. If the teaching answer offered multiple recipes for different scenarios, disambiguate first.
