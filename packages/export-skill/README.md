# export-skill

Export a skill so others can use it. Thin orchestrator that chains five sub-skills, each also user-invocable on its own when you only need part of the flow.

## Commands

### `/export-skill <skill-name> [en|nl|linux|windows|macos]`

Runs the full pipeline: sanitize, optionally translate or port, package, share. Source skill lives in `~/.claude/skills/`.

## Sub-skills (also user-invocable)

### `/export-skill:sanitize <skill-name-or-path>`

Strip PII (home paths, names, internal URLs, credentials, tokens) and flag security issues. The single step that makes a skill safe to leave the machine.

### `/export-skill:translate <skill-name-or-path> <en|nl>`

Translate body text between Dutch and English. Frontmatter and code stay in the original language.

### `/export-skill:port <skill-name-or-path> <linux|windows|macos>`

Replace platform-specific commands (`say`, `pbcopy`, `osascript`, `brew`, etc.) with target equivalents.

### `/export-skill:package <dir-path>`

Bundle a skill directory into transportable form. Single-file directories (only a `SKILL.md`) emit as `{name}-SKILL.md`. Multi-file directories become `{name}.zip`.

### `/export-skill:share <file-or-dir-path>`

Hand off the packaged skill: writes a sharing summary, stashes it for `/clipboard`, opens the parent directory in Finder, and prints a report. macOS-only handoff.

## Installation

```bash
/plugin install export-skill@leclause
```
