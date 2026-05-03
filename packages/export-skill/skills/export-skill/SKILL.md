---
name: export-skill
user-invocable: true
description: Use when the user wants to export/share a skill with others. Thin orchestrator that chains sanitize, optional translate or port, package, and share. For partial workflows, invoke the sub-skills directly.
argument-hint: "<skill-name> [en|nl|linux|windows|macos]"
allowed-tools:
  - Skill
  - Bash(ls *)
effort: low
---

# Export Skill

Export a skill from `~/.claude/skills/` as a sanitized and packaged file, ready to share. This skill is a thin orchestrator: each step below is exactly one Skill tool invocation. No inline rules, no own PII matrix or platform matrix: those live in the sub-skills.

## Invocation

```
/export-skill say              # sanitize + package + handoff
/export-skill say en           # sanitize + translate to English + package + handoff
/export-skill say nl           # sanitize + translate to Dutch + package + handoff
/export-skill say linux        # sanitize + port to Linux + package + handoff
/export-skill say windows      # sanitize + port to Windows + package + handoff
```

First argument: `{{NAME}}` = name of a skill directory in `~/.claude/skills/`.
Second argument (optional): `{{SUFFIX}}` = target language (`en`/`nl`) or target platform (`linux`/`windows`/`macos`).

## Orchestration

Each step is a `Skill` tool invocation. The output of step N is the input of step N+1. Track the `CURRENT_PATH` variable at each step; it starts empty and is set after each step to the path produced by the sub-skill.

### Step 1. Sanitize (always)

```
Skill(skill="export-skill:sanitize", args="{{NAME}}")
```

Expected output: directory `/tmp/skill-exports/{{NAME}}/`. Set `CURRENT_PATH = /tmp/skill-exports/{{NAME}}/`.

### Step 2. Transform (only if `{{SUFFIX}}` given)

For language (`en`/`nl`):

```
Skill(skill="export-skill:translate", args="{{CURRENT_PATH}} {{SUFFIX}}")
```

For platform (`linux`/`windows`/`macos`):

```
Skill(skill="export-skill:port", args="{{CURRENT_PATH}} {{SUFFIX}}")
```

Expected output: directory `/tmp/skill-exports/{{NAME}}-{{SUFFIX}}/`. Set `CURRENT_PATH = /tmp/skill-exports/{{NAME}}-{{SUFFIX}}/`.

Skip step 2 if there is no second argument.

### Step 3. Package

```
Skill(skill="export-skill:package", args="{{CURRENT_PATH}}")
```

Expected output: file `{{CURRENT_PATH%/}}.zip` or `{{CURRENT_PATH%/}}-SKILL.md` (depending on the number of text files in the directory). Set `CURRENT_PATH` to the new path.

### Step 4. Handoff

```
Skill(skill="export-skill:share", args="{{CURRENT_PATH}}")
```

share reads the source SKILL.md (from a directory or a standalone `-SKILL.md` file), opens Finder on the parent, and ends with a summary as the last answer so that `/clipboard` copies it.

When the input is a `.zip`, point `share` to the original directory (from step 3) or to the single-file `-SKILL.md` alternative. share does not read zip files.

### Error handling

If a Skill invocation fails or does not produce the expected output, stop the chain and report the error including which step failed and which path was missing. Do not jump to the next step.

## Standalone use

Each sub-skill is also independently user-invocable. Use the sub-skills directly if you only need part of the workflow:

- `/export-skill:sanitize <name>` to only strip PII.
- `/export-skill:translate <path> <en|nl>` to translate.
- `/export-skill:port <path> <linux|windows|macos>` to port.
- `/export-skill:package <path>` to zip an arbitrary directory or emit it as a single-file md.
- `/export-skill:share <path>` to do summary + Finder handoff on an existing export.

The orchestrator is a convenience for the most common flow: "I want to share this skill with someone."

### Common combinations

- **Port for personal use** (not sharing, no Finder): `/export-skill:port <name> linux`. Writes to `~/.claude/skills/<name>-linux/`, no `/tmp/skill-exports/`, no package, no Finder.
- **Translate AND port**: the orchestrator does only one transformation at a time. For the combination, chain manually: `sanitize` -> `translate` -> `port` -> `package` -> `share`.
- **Repackage only** (re-bundle an already-exported dir): `/export-skill:package /tmp/skill-exports/<name>/`.

## Upfront validation

- `{{NAME}}` must correspond to an existing directory in `~/.claude/skills/`. Check with `ls ~/.claude/skills/{{NAME}}/`. If it does not exist, stop before step 1.
- `{{SUFFIX}}` must (if present) be one of `en`, `nl`, `linux`, `windows`, `macos`. Otherwise stop with an error before step 2.
- If `/tmp/skill-exports/{{NAME}}/` already exists, stop with a clear message so the user can clean up manually.
