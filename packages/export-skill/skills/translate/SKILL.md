---
name: translate
user-invocable: true
description: Use when translating a Claude Code skill between Dutch and English. Operates on a source skill directory in `~/.claude/skills/` or on an already-exported path. Applies translate rules consistently: body text yes, frontmatter and code no.
argument-hint: "<skill-name-or-path> <en|nl>"
allowed-tools:
  - Bash(ls *)
  - Bash(file *)
  - Bash(mkdir -p *)
  - Read(*)
  - Write(**)
effort: low
---

# Translate Skill

Translate the text of a skill between Dutch and English. Source files remain untouched; the translated version is written alongside them. No sanitization, no porting: only language transformation. For sanitization see `sanitize`; for platform porting see `port`.

## Invocation

```
/export-skill:translate say en                        # source: ~/.claude/skills/say/, target: English
/export-skill:translate saysay nl                     # source: ~/.claude/skills/saysay/, target: Dutch
/export-skill:translate /tmp/skill-exports/say/ en    # source: exported directory
/export-skill:translate /tmp/skill-exports/say-SKILL.md en   # source: standalone file
```

First argument: skill name or path. Second argument: target language (`en` or `nl`).

## Input resolution

- If the first argument contains no `/`, `.`, or `~`, interpret it as a skill name and resolve to `~/.claude/skills/<name>/`.
- If it is a path (starts with `/`, `./`, or `~`), use it directly. Accept both directory and standalone file.
- Follow symlinks. If the source does not exist, report this and stop.

## Output policy

- **Directory input:** write to `<source-parent>/<name>-<lang>/` (e.g. `~/.claude/skills/say-en/`). For `/tmp/skill-exports/` input, write alongside the source: `/tmp/skill-exports/<name>-<lang>/`.
- **Standalone file input:** write alongside the source with `.<lang>.md` suffix (e.g. `/tmp/skill-exports/say-SKILL.en.md`).
- Never overwrite without warning. If the destination already exists, report this and stop (user can clean up manually).

## Steps

1. **Validate** source exists and target language is `en` or `nl`.
2. **Inventory** text files in the source (use `file` for text/binary detection).
3. **Translate** each text file according to the translation rules below. This is LLM work, not regex-replace.
4. **Copy** binary files as-is; report them as skipped.
5. **Write** the translated version to the destination.
6. **Report** what was translated and what was left untranslated.

## Translation rules

### What to translate

- SKILL.md body text (descriptions, instructions, examples)
- Comments in scripts
- Usage strings and help text
- Example output
- Section headers in Markdown (except where the header is a technical term)

### What NOT to translate

- Frontmatter `name` and `description` (always English; these are also the channel through which skill activation runs)
- Code (variables, functions, commands, shell snippets, JSON/YAML values)
- Technical terms that sound unnatural in the target language (e.g. "commit", "repository", "prompt")
- Filenames and paths
- URLs
- String values in code blocks (unless they are clearly UI text the user sees)

### Consistency

- The same source term gets the same translation in all files of the same skill.
- When in doubt between a technical term and a Dutch term: choose the Dutch variant only if it is common among developers.
- Tone and register remain consistent with the original (informal stays informal, imperative stays imperative).

## Report template

```
## Translation: {name} -> {lang}

**Source:** {path}
**Destination:** {path}

### {filename}
- Translated: {brief description of the sections}
- Left untranslated: {technical terms, code blocks, frontmatter}

### Binaries
- {filename}: copied without modification
```

## Composition

This skill does one thing. For a complete export flow, chain it with other skills:

```
/export-skill:sanitize say                            # strip PII, output /tmp/skill-exports/say/
/export-skill:translate /tmp/skill-exports/say/ en    # translate the sanitized directory
/export-skill:package /tmp/skill-exports/say-en/      # zip or md
```

Or use the orchestrator in one step: `/export-skill say en` does sanitize + translate + package + share.

The order sanitize-before-transform matters: transforming an unsanitized file leaks PII into the translation.
