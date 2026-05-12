---
name: drydry
user-invocable: true
description: Use when you suspect parallel paths exist in any artefact (code in any language, prose, design systems, technical documentation), or when a colleague or you yourself just wrote something that smells familiar. Triggers on "/drydry:drydry", "is dit een dubbeling?", "did I write this somewhere else?", "are these two doing the same thing?", "audit dit op duplication". Routes between a quick inline check (small scope, no artefact) and a full audit (large scope, produces a findings markdown). Six agent-only sub-skills handle detection, checklist bootstrap, triage, online research, cross-toolbox audit, and CLAUDE.md audit.
allowed-tools:
  - Skill
  - Agent
  - Bash(git status *)
  - Bash(git log *)
  - Bash(git diff *)
  - Bash(date *)
  - Bash(ls *)
  - Bash(find *)
  - Bash(grep *)
  - Bash(rg *)
  - Bash(wc *)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
effort: high
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the drydry plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("drydry was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new drydry`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Drydry Orchestrator

"Is dit een dubbeling?" becomes a discipline with a runbook, not a vibe-check. This skill is the one user-invocable surface of the `drydry` plugin. It routes between two modes and dispatches the six agent-only sub-skills that do the substance.

The framework rests on eight concepts (see `README.md` for the full text): Type-4 clone framing, verifier-burden discipline on LLM-found hits, allow-list scoping via checklist, drift hypothesis per finding, three-bucket convergence triage, two-fates discipline, contrarian second-pass on rejects, detection method as first-class artefact. The orchestrator does not enforce all eight in every invocation; quick mode skips the heavier discipline because the scope does not need it. Audit mode applies all eight.

## Routing

Two modes. The orchestrator picks one before doing any work.

### Explicit keyword wins

When `args` contains explicit routing keywords, route accordingly without further inspection. Two equivalent forms are accepted (the bare form is what an operator types after `/drydry:drydry`; the keyed form is what an autonomous caller passes through `args`):

- `quick` or `mode: quick` -> quick mode
- `audit` or `mode: audit` -> audit mode
- `sweep` / `checklist` / `triage` / `learn` / `upstream` / `instructions`, or `skill: <name>` -> dispatch that sub-skill directly with the remaining args as its input

### Implicit signal from context

Read what the operator pasted, what is in the recent transcript, and what `git status` shows. Beyond `args` the frontmatter allows `git status`, `git log`, `git diff` to gauge recent activity.

- **Quick mode** is the right fit when:
  - The operator pasted two snippets, two file references, or a transcript excerpt
  - The scope is a single file or a pair of files
  - The phrasing is ad-hoc ("wacht eens, is dit dubbel?", "did I just write this?", "are these the same?")
  - The expected output is an inline yes/no plus a runnable verifier, not a full report

- **Audit mode** is the right fit when:
  - The operator names a directory, package, or project root
  - The scope is "audit our codebase for duplication"
  - The phrasing suggests breadth ("walk the project", "find the parallel paths", "do a full sweep")
  - The operator mentions a domain hint (Swift, Rails, prose, design-tokens) that maps to a checklist

### Default and override

Present the chosen mode in one short line before dispatching. Example:

> Two snippets in scope, no explicit mode keyword. Routing to **quick mode**. Type `audit` to switch to the full pipeline.

Or:

> Directory `app/models/` named, no explicit mode keyword. Routing to **audit mode**. Type `quick` to switch to an inline check.

When `args` carries explicit intent (the keyword above), skip the proposal line and dispatch immediately.

### No signal

When `args` is empty and the conversation gives no clear scope, ask one short question:

> Two modes available: `quick` for an inline check on a small scope, `audit` for a full sweep producing a findings artefact. Which fits, and what is the scope?

Ask this question **once**. The answer is binding; do not confirm again.

## Quick mode

Cheap, scoped, no artefact. The goal is to answer "are these two paths a duplicate?" in the operator's working session, with enough rigour that the answer is not a vibe-check but also not the full eight-chapter discipline.

Steps:

1. **Identify the two (or more) candidates.** Read them: the paste, the named files, the transcript excerpt. If the operator named only one item, ask the operator to point at the suspected duplicate. (Do not invent the comparison target.)
2. **Apply the drift-hypothesis test (Chapter 4).** Write one sentence: "what bad thing happens if these two paths keep drifting?" If the sentence is "the code is a bit messy" or "it would be cleaner to share", the finding is not yet sharp enough. Push back: "I do not see a drift hypothesis here. Sharpen the question or accept that this is style overlap, not a duplicate."
3. **Apply the verifier-burden discipline (Chapter 2).** Produce one runnable command (a `grep`, `rg`, `ast-grep` query, or a `find ... -exec` pair) that re-verifies the duplication without the LLM in the loop. Show the command and its expected output.
4. **Verdict.** One paragraph. Three possible verdicts:
   - **Duplicate, cheap-and-safe to converge.** Name the convergence direction in one sentence and the cost.
   - **Duplicate, but needs design.** Name the open question that has to be resolved before convergence (which side wins, what to name the unified abstraction, how callers migrate).
   - **Not a duplicate.** Explain why the structural similarity does not imply a shared behaviour contract.
5. **Side quests, if any.** If the inspection surfaced something out-of-scope ("we should also look at X", "Y feels related"), list it as a side quest. Do not detour to address it now.

Output is inline conversational, no markdown file. Pride and gurus gates do not run in quick mode; the scope does not warrant the cost.

## Audit mode

Full eight-chapter discipline. Produces a `<scope>-drydry-findings.md` artefact in the current working directory. Pride second-pass on rejects (Chapter 7). Gurus pass is **deferred to a follow-up decision** (see Side quests).

Steps:

1. **Resolve scope.** Read what the operator named: a directory, a glob, a package, a project root. Run `wc -l $(find <scope> -type f \( -name '*.swift' -o -name '*.rb' -o ... \))` to gauge size. If the scope is unclear, ask once.
2. **Bootstrap or load the checklist.** Dispatch `drydry:checklist` via the Skill tool. Pass the domain hint (Swift/SwiftUI, Rails, React/TypeScript, Markdown prose, design tokens) and any seed patterns the operator named. The sub-skill returns a six-to-ten item checklist.
3. **Dispatch `drydry:sweep`.** Pass the scope and the checklist. The sub-skill spawns a Sonnet subagent with verifier-burden discipline; hits without a runnable verifier are dropped. The sub-skill returns a findings list with tuples `(pattern_id, file_a:line_a, file_b:line_b, drift_hypothesis, verifier_command)`.
4. **Dispatch `drydry:triage`.** Pass the findings list. The sub-skill classifies each finding into cheap-and-safe / partial / needs-design with a one-line cost note.
5. **Apply Chapter 7 (contrarian second-pass on rejects).** For every finding the sub-skill classified as `needs-design` (which includes the `by-design` sub-case where convergence is blocked by a framework or external API), spawn a second Sonnet subagent via the Agent tool with a contrarian brief ("is this rejection hollow?"). A reject is final only if the contrarian independently confirms it as hollow.
6. **(Optional) Dispatch `drydry:upstream`.** When the operator named a framework (Rails, Devise, SwiftUI, React) or when the project has a recognisable manifest (Gemfile, Package.swift, package.json), include a cross-toolbox section: does the operator have helpers that duplicate framework functionality?
7. **(Optional) Dispatch `drydry:instructions`.** When the project has CLAUDE.md files (project-level or referenced from user-level), include a CLAUDE.md audit section: do the instructions themselves cause DRY violations?
8. **Write the artefact.** Two-section markdown file: `## Detection method chosen` (the checklist version, the sub-skills invoked, the verifier conventions; Chapter 8) and `## Findings` (one subsection per checklist item with the verified hits, drift hypotheses, triage, and contrarian verdict if applicable). Add `## Checklist gaps` when the sweep surfaced "interesting but off-list" hits (Chapter 3 keeps them out of the findings proper). Add `## Side quests` when out-of-scope follow-ups surfaced.

Note on `drydry:learn`. The audit pipeline above does NOT dispatch `learn` as part of a normal run; `learn` is a one-off enrichment that updates the checklist vocabulary from external sources and is invoked explicitly via `/drydry:drydry learn <topic>`. Audit mode reuses whatever checklist the most recent `learn` run produced (via `drydry:checklist`'s seed templates), but does not trigger a fresh `learn` itself. See the Sub-skills table below for the full when-to-dispatch matrix.
9. **Report.** One short summary to the operator: scope, number of findings, triage breakdown, path to the artefact.

The artefact is written to the project root by default, named `<scope>-drydry-findings.md` where `<scope>` is a slug of the directory or package the audit covered. The operator decides whether to convert findings into commits, or to address them out-of-process; that decision is not the orchestrator's.

## Skill-invoked (autonomous callers)

When this orchestrator is invoked by another skill rather than typed by the operator (a rover at INSPECT, an auto-loop, or any future caller that passes context through `args`), the operator is not in the loop and cannot answer a routing question. Routing must complete from `args` alone.

Detection: `args` carries explicit mission context (a scope, a checklist, a mode keyword, a domain hint, a directory path). Treat any non-empty caller-supplied context as the autonomous path.

Rules in this mode:

- **Never ask the operator.** The "ask once" fallback in the No-signal section does not apply. If the implicit signals are weak, pick a default and dispatch.
- **Default when ambiguous:** if `args` references a directory, package, or multi-file scope -> audit mode; if `args` references two snippets, one file, or a transcript excerpt -> quick mode; if `args` names a sub-skill explicitly, dispatch that sub-skill directly.
- **Caller-named mode wins.** `mode: quick` or `mode: audit` in `args` (or the equivalent bare token `quick` / `audit`) bypasses inference. The Routing section above lists both forms as equivalent; either is accepted here too.
- **Caller-named sub-skill wins.** `skill: sweep` (etc.) in `args`, or the bare token `sweep` / `checklist` / `triage` / `learn` / `upstream` / `instructions`, dispatches that sub-skill directly with the remaining args as its input.
- **No proposal line, no override prompt.** Produce the verdict or the artefact directly.
- **Pride and gurus gates** are the caller's responsibility, not the orchestrator's. A rover at INSPECT has already scheduled its own pride and gurus passes; the orchestrator does not double-up.

The contract: a skill-invoked call always produces a verdict (quick mode) or an artefact (audit mode) and never bounces back a question.

## Sub-skills

| Sub-skill | When the orchestrator dispatches it | When the operator may hint it |
|-----------|-------------------------------------|-------------------------------|
| `drydry:sweep` | Always in audit mode (step 3) | When the operator already has a checklist and wants the detection pass directly |
| `drydry:checklist` | Always in audit mode (step 2) | When the operator wants a starter checklist for a new domain without running a sweep |
| `drydry:triage` | Always in audit mode (step 4) | When the operator already has a findings list and wants it triaged |
| `drydry:learn` | Never in a normal audit run; this is a one-off enrichment | When the operator says "wat zegt de wereld over duplication?" or "update the checklist seeds" |
| `drydry:upstream` | Conditionally in audit mode (step 6) when a framework is detected or named | When the operator says "audit alleen tegen Rails/SwiftUI/React conventies" |
| `drydry:instructions` | Conditionally in audit mode (step 7) when CLAUDE.md files exist in scope | When the operator says "audit alleen mijn CLAUDE.md" |

All six are agent-only (`user-invocable: false`). The operator never types `/drydry:sweep`; the operator types `/drydry:drydry sweep <scope>` or hints the sub-skill in their prompt and the orchestrator routes.

## Rules

- **Routing is fast.** At most one question before dispatching. A second question is a failure mode.
- **Explicit intent wins.** When `args` names a mode or a sub-skill, skip the proposal line.
- **Do not detect duplicates yourself.** The orchestrator routes and writes the artefact; detection happens in `drydry:sweep`. Stay neutral on which findings are "real".
- **Quick mode does not run pride or gurus.** Audit mode runs pride's contrarian second-pass on rejects (Chapter 7); gurus is a deferred decision (see Side quests).
- **Hits without a runnable verifier are dropped.** This is enforced in `drydry:sweep`, not here, but the orchestrator may discard a hit that resurfaces without one.
- **The drift hypothesis is the gate.** A finding without a sharp drift hypothesis is not a finding; it is style overlap. Both modes apply this.
- **Verifier proves existence, not semantic equivalence.** The runnable command (`grep`, `rg`, `ast-grep`) confirms both locations exist; it does not confirm the drift hypothesis is real or that the two paths share a behaviour contract. Every finding is a candidate until a human reads both paths. False positives are most common in the Type-4 case (semantic equivalence claimed across structurally different code); the verifier alone cannot catch a wrongly-classified semantic match.
- **A clean report is scoped to the checklist, not to the codebase.** Chapter 3's allow-list discipline means the sweep finds only what the checklist names. Zero findings on a sharp checklist proves the listed patterns are absent; it does not prove the codebase has no duplication. The `## Checklist gaps` section in the artefact is the signal that the checklist needs extending in a follow-up sweep.

## Side quests (deferred decisions, do not address in this skill)

- **Pride and gurus gates on `drydry:drydry` itself.** Quick mode skips both for cost reasons; audit mode runs pride on rejects but not on the whole artefact, and gurus is not invoked at all. The full pride-on-artefact and gurus-on-public-surface gates the rover applies at INSPECT do not apply when a human operator types `/drydry:drydry` directly. Decide whether to add them once the plugin has seen real use.
- **Out-of-process follow-ups.** When a finding's convergence has to happen out-of-process (a separate session, a separate mission), the artefact currently logs it under `## Side quests` without a structured handoff format. Concrete trigger to formalise: the first audit run where the operator triages a finding as cheap-and-safe but names a separate session for the convergence work. At that point, add a structured handoff format (mission slug, scope, evidence pointers) to the artefact template.
