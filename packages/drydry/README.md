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

Six agent-only sub-skills handle the substance: `sweep`, `checklist`, `triage`, `learn`, `upstream`, `instructions`. The operator does not invoke them directly; the orchestrator routes. The operator can hint a sub-skill by name in the prompt and the orchestrator will dispatch.

## The eight chapters

_To be filled in by step 7 of the build._

## Example checklist seeds

_To be filled in by step 7 of the build._

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
