# drydry

Find and converge parallel paths in any artefact: code in any language, prose, design systems, technical documentation. The name nods to DRY (Don't Repeat Yourself); doubling the word reinforces that the framework is about *drying up* parallel paths that already exist, not the original aspirational principle.

The plugin's value: "is dit een dubbeling?" becomes a discipline with a runbook, not a vibe-check.

## Install

```bash
claude plugins install drydry@leclause
```

## How to invoke

One user-invocable surface: `/drydry:drydry`. The orchestrator routes between two modes:

- **Quick mode**: ad-hoc "is this duplicate?" check mid-session. Inline answer with a runnable verifier-grep. No artefact. Trigger with `quick` in the prompt or by naming a small scope (two snippets, a transcript reference).
- **Audit mode** (default for non-trivial scope): full sweep producing a `<name>-drydry-findings.md` artefact with `## Detection method chosen` and `## Findings` sections, plus a `## Side quests` section when out-of-scope work surfaces.

Six agent-only sub-skills handle the substance. Three of them implement the eight-chapter framework directly: `sweep` (Chapter 2 verifier-burden detection), `checklist` (Chapter 3 allow-list bootstrap), `triage` (Chapter 5 three-bucket convergence). The other three are extensions outside the eight chapters that the operator can dispatch when the duplication question crosses an axis the core pipeline does not cover: `learn` (online research enriching the pattern vocabulary), `upstream` (operator code versus framework offerings), `instructions` (CLAUDE.md as a duplication-cause). The operator does not invoke any sub-skill directly; the orchestrator routes. The operator can hint a sub-skill by name in the prompt and the orchestrator will dispatch.

## The eight chapters

The drydry framework rests on eight concepts. Three are established literature, two are local terminology (originating in the `leclause/autonomous` rover protocol), three are improvisation that holds under contrarian review. Each chapter applies across mediums (code, prose, design); the medium-translation paragraph after each chapter shows how.

### Chapter 1: Type-4 clone framing

**Established.** The standard taxonomy of code clones is four levels:

- **Type-1**: identical copies (whitespace and comments aside).
- **Type-2**: identical structure with renamed identifiers.
- **Type-3**: structurally similar with added or removed or modified statements.
- **Type-4**: same behaviour, different structure.

Token-based detectors (jscpd, PMD CPD, SwiftLint custom rules, Simian) are reliable for Type-1 through Type-3 because tokens carry the signal. They miss Type-4 by design, because semantic equivalence does not show up in the token stream. The Type-4 case is what hurts most over months in actively maintained codebases: token detectors miss it, so it accumulates invisibly, while Type-1 through Type-3 stay visible to existing tooling. Two stop-confirmation surfaces, two snapshot factories, two error-handling middlewares, two onboarding banners that drift apart copy-by-copy are typical shapes.

**Medium translation.** In prose: two paragraphs that say the same thing in different words across a chapter or a doc set. Token-detectors miss this because the wording is fresh; semantic-detectors find it. In design: two components that solve the same UX need (a confirm-action popover and a confirm-action sheet) with different visual languages. Visual diff tools see them as different; the user feels the inconsistency.

Sources: Roy and Cordy 2007 ("A Survey on Software Clone Detection Research", Queen's School of Computing TR 2007-541), plus a continuing line of embedding-based Type-4 detection work in the years since. See `drydry:learn` for a current literature sweep when a specific paper is needed.

### Chapter 2: LLM pass with verifier-burden discipline

**Improvisation, verified in practice.** Every LLM-generated finding arrives bundled with a runnable command that re-verifies the finding without the LLM in the loop. In code, that is a `grep`, `rg`, `ast-grep` query, or a `find ... -exec` pair pointing at the divergent files. In prose, it is a regex matching the duplicated semantic pattern across the markdown corpus. In design, it is the two component paths or the two Figma node IDs.

The discipline closes one common LLM-output failure mode: hallucinated-confidence findings that look plausible but reference files, lines, or features that do not exist. Without the verifier command, the rapport is the LLM's word against the operator's grep; with it, the rapport contains its own counter-test. Hits without a runnable verifier are dropped (enforced in `drydry:sweep`).

The verifier proves existence, not semantic equivalence. A `grep` that re-finds both locations confirms the files and lines exist; it does not confirm the drift hypothesis is real or that the two paths share a behaviour contract. Every finding is a candidate until a human reads both paths; false positives are most common in the Type-4 case where the LLM claimed semantic equivalence between structurally different code.

**Medium translation.** Code findings carry tuples `(pattern_id, file_a:line_a, file_b:line_b, drift_hypothesis, verifier_command)`. Prose findings carry `(pattern_id, doc_a:section_a, doc_b:section_b, drift_hypothesis, regex_or_search_query)`. Design findings carry `(pattern_id, component_a, component_b, drift_hypothesis, design-system query)`.

Family in literature: adjacent to "tool-grounded generation", "retrieval-augmented verification", and "self-consistency with provenance". Improvisation, not yet named in the literature.

### Chapter 3: Allow-list scoping (checklist over open search)

**Established as a discipline.** Atul Gawande's *The Checklist Manifesto* (2009) is the canonical reference; the lineage runs back through aviation pre-flight, surgical safety checklists (WHO 2008), SOC2 audit programs, NIST control frameworks. The principle: when the question is "find X in this haystack", the search space is too large for open-ended exploration. The operator commits to a short, named list of patterns up front; the audit succeeds or fails against that list, not against an unbounded sense of "did we catch everything".

In drydry: every audit run starts with a checklist of six to ten patterns (bootstrapped by `drydry:checklist`). The Sonnet pass is allowed to find anything from that list. It is *not* allowed to invent new categories on the fly; "interesting but off-list" findings go to a `## Checklist gaps` section in the rapport for the operator to fold into the next sweep, not into this one. The separation prevents subagent scope-drift and keeps the rapport deterministic.

A clean report is scoped to the checklist, not to the codebase. Zero findings on a sharp checklist proves the listed patterns are absent; it does not prove the codebase has no duplication. The `## Checklist gaps` section is the signal that the checklist needs extending in a follow-up sweep.

**Medium translation.** The seed templates in `drydry:checklist` cover iOS/SwiftUI, Rails, React/TypeScript, Markdown prose, and design tokens. A generic fallback exists for projects that do not match any baked-in seed.

### Chapter 4: Drift hypothesis per finding

**Improvisation.** Every accepted finding comes with one sentence answering the question "what bad thing happens if these two paths keep drifting?". Without that sentence, the finding is observation, not work. The hypothesis distinguishes "two files happen to look alike" from "two paths share a behaviour contract that will break silently if they drift". It is the gate that turns surface-similarity into actionable similarity.

**Discipline test.** If the drift hypothesis reads "the code is a bit messy" or "it would be cleaner to share", the finding is not yet sharp enough to land. Real drift hypotheses sound like "fixture A bypasses the activePlates derivation that fixture B has, so the Live Activity badge silently disappears on path A" or "the resident-confirm popover and the visitor-confirm sheet diverged on copy capitalisation, and the localisation team has been chasing the inconsistency for three sprints".

**Medium translation.** In prose: "the outdated retry-after value will be cited in a customer support ticket within the quarter". In design: "a user encountering both the dialog and the sheet form learns two patterns for the same action, and the inconsistency erodes the trust the design system is supposed to build".

### Chapter 5: Three-bucket convergence triage

**Generic, not named externally.** Findings without an action plan are decoration. Every finding lands in exactly one of three buckets:

- **cheap-and-safe**: there is an obvious convergence direction, the change is local, no public contract moves. Land it in the same audit.
- **partial overlap**: convergence requires design judgement (which side wins, what to name the unified abstraction, how callers migrate). Surface the design question in the artefact under `design_question:`; promote to cheap-and-safe when the operator answers.
- **needs-design / by-design**: looks like drift but is actually constrained by a framework, an external API shape, or a genuine domain difference. Document why it is *not* drift so future audits do not re-flag it.

The framing rhymes with ICE (Impact/Confidence/Ease), RICE, and defect-triage matrices from QA literature. Three buckets is the plugin's chosen minimum: fewer buckets lose the design-judgement case, more buckets dilute decisions. The bucket is the verdict; the cost is the evidence for the verdict.

### Chapter 6: Two-fates discipline (fix or reject-with-evidence)

**Local terminology** (originating in the `leclause/autonomous` rover protocol). Every finding the audit raises leaves the audit in one of exactly two states:

- **Fixed**, with the diff or edit in the audit's commit or edit trail.
- **Rejected**, with concrete evidence that the finding was a non-issue.

There is no third state. "Later", "polish for the next sprint", "the team can decide", "backlog": all are deferrals dressed up. They are the failure mode the discipline exists to prevent. Closest external relatives: zero-bug policy in XP, "stop-the-line" in the Toyota Production System, "ratchet" in critical-systems engineering. The drydry framing is sharper than any of those because the rejection carries an evidence-burden, not just an opinion-burden.

### Chapter 7: Contrarian second-pass on rejects

**Local terminology** (originating in the `leclause/autonomous` rover protocol). The fix-or-reject rule has an obvious failure mode: the author is the one classifying. They built the work, so they have every incentive to wave a finding away. A threshold-based gate ("run a second pass only if rejects exceed X%") admits an unsupervised band; any threshold above zero is defensible only by feel.

The drydry rule is flat: **any reject triggers an independent contrarian pass.** A second Sonnet subagent gets the rejected finding and the author's evidence, with a brief that explicitly biases toward "is this rejection hollow?". A reject is final only if the contrarian independently confirms it as hollow. The cost is bounded (one extra subagent call per reject); the benefit is that the author's blind spot is no longer load-bearing.

External relatives: red-team review, devil's advocate (canonised by Aquinas, then by management consulting), challenger reviews in safety-critical engineering, NASA's mishap-review boards.

### Chapter 8: Detection method as first-class artefact

**Established.** Reproducibility hygiene. The rapport contains not just the findings but the method that produced them: scope (which directories, which exclusions), checklist (which patterns, which version), tool (which subagent prompt, which verifier conventions). Operators rerunning the audit a quarter later reproduce the run without re-deriving the method from a Slack thread.

References: the "methods section" convention in academic papers; SRE runbooks; compliance audit trails (SOC2, ISO 27001); reproducible-research conventions in scientific computing.

In drydry: every audit run produces a `<scope>-drydry-findings.md` artefact in two halves, `## Detection method chosen` at the top, `## Findings` below. The method paragraph cites the checklist version, names the subagent, lists the verifier conventions. If the rapport later turns out to be wrong, the method paragraph is what the operator inspects to understand *why* the method missed it, so the next sweep can be sharper.

## Example checklist seeds

Two of the three example domains from the framework's original write-up appear below as a starting point. The full set of seed templates lives in `packages/drydry/skills/checklist/SKILL.md` and covers iOS/SwiftUI, Rails, React/TypeScript, Markdown prose, and design tokens; the snippets here illustrate the *shape* of a seed so a new operator can extend the plugin for their domain.

### Example A: code (Rails)

```markdown
## Checklist: rails v2026-05-12T14-00

### service-objects: overlapping responsibilities

Service classes whose names suggest a shared responsibility (UserCreator,
UserOnboarder, UserRegistration) but whose boundaries have drifted.
Drift typically manifests as one service writing a column the other
service is supposed to own; over time the team forgets which one is
canonical.

Signatures to look for:
- `class .*(Creator|Onboarder|Registration|Setup)\b`
- `def create_user|def onboard_user|def register_user`

### activerecord-scopes: parallel predicates

Scopes encoding the same predicate (`active`, `enabled`, `not_archived`)
across or within models. Drift typically manifests when a model adds a
soft-delete column and only half the call-sites learn about it.

Signatures to look for:
- `scope :(active|enabled|not_archived|live|visible)`
- `where\(.*archived_at.*nil\)`

### authorisation-paths: two ways to authorise

Pundit policies and `before_action :authenticate!` chains coexisting for
the same endpoint. The drift manifests when a new endpoint copies one
pattern and a refactor copies the other, leaving the codebase split.

Signatures to look for:
- `before_action :(authenticate|authorize)!`
- `authorize @`
```

### Example B: prose

```markdown
## Checklist: markdown-prose v2026-05-12T14-00

### duplicate-definitions: a term defined twice

A glossary term defined in two places with slightly different wording.
Drift manifests when the team updates one definition and forgets the
other; readers find both and assume the inconsistency is intentional.

Signatures to look for:
- `^### .*: ` followed by a definition paragraph (use heading-level scan)
- `<dfn>.*</dfn>` in HTML body prose

### redundant-safety-paragraphs: copy-pasted disclaimers

A rate-limit or auth-required warning paragraph repeated across multiple
guides. Drift manifests when one paragraph's retry-after value is
updated and the others continue to cite the stale value, which then
shows up in customer support tickets.

Signatures to look for:
- `rate.?limit|retry.?after|requires? authentication`
- exact-match phrase search across all `*.md` files

### terms-of-art-inconsistency: same concept, two terms

The same domain concept named "tenant" in one place and "customer" in
another within one doc set. Drift manifests in cross-references and
breaks the reader's mental model when they switch sections.

Signatures to look for:
- `\b(tenant|customer|account|workspace)\b` with co-occurrence analysis
```

The third example domain (design systems) appears in full in `packages/drydry/skills/checklist/SKILL.md`. The two examples above are enough to show a new operator how to extend the plugin for a domain the seed templates do not yet cover: write a checklist with the same shape, hand it to `drydry:sweep` via the orchestrator's `audit` mode.

## Skills in this plugin

| Skill | User-invocable | Purpose |
|-------|:---:|---------|
| `drydry:drydry` | yes | Orchestrator. Routes to a sub-skill or runs the audit pipeline directly. Quick and audit modes. |
| `drydry:sweep` | no | Detection pass. Spawns Sonnet subagent with verifier-burden discipline. |
| `drydry:checklist` | no | Bootstraps a 6-to-10 item checklist per domain. |
| `drydry:triage` | no | Three-bucket triage (cheap-and-safe / partial / needs-design). |
| `drydry:learn` | no | Online research on de-duplication state-of-the-art. |
| `drydry:upstream` | no | Cross-toolbox audit against framework offerings. |
| `drydry:instructions` | no | CLAUDE.md audit for instructions that cause DRY violations. |
