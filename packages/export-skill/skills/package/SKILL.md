---
name: package
user-invocable: true
description: Use when bundling a skill directory into transportable form. Single-file directories (only a SKILL.md) emit as `{name}-SKILL.md`. Multi-file directories become `{name}.zip`. Purely mechanical, no content transformation.
argument-hint: "<dir-path>"
allowed-tools:
  - Bash(ls *)
  - Bash(file *)
  - Bash(zip *)
  - Bash(rm -rf /tmp/skill-exports/*)
  - Bash(mkdir -p *)
  - Read(*)
  - Write(**)
effort: low
---

# Package Skill

Bundle a skill directory into a transportable form. Mechanical work: a directory containing only `SKILL.md` becomes a standalone `.md` file (readable on iPhone without unzip). A directory with multiple files becomes a `.zip`.

No content transformation: this skill does not change the text. For sanitization see `sanitize`, for translation `translate`, for porting `port`.

## Invocation

```
/export-skill:package /tmp/skill-exports/say/            # directory with multiple files -> say.zip
/export-skill:package /tmp/skill-exports/say-en/         # translated directory -> say-en.zip
/export-skill:package ~/.claude/skills/saysay/           # directory with only SKILL.md -> saysay-SKILL.md (for local use only; run sanitize first before sharing)
```

Single argument: path to the directory you want to bundle.

## Steps

1. **Validate** that the argument is an existing directory.
2. **Count** the text files in the directory (use `file`).
3. **Decide format:**
   - Exactly one text file, and that file is named `SKILL.md`: emit `{parent}/{name}-SKILL.md` by copying SKILL.md directly with the new name.
   - Otherwise: create a zip.
4. **If zip:** run `cd {parent} && zip -r {name}.zip {name}/`. The intermediate directory can then be removed, but ONLY if the input is under `/tmp/skill-exports/`. Never remove sources outside that location.
5. **Report** the resulting file and whether the intermediate directory was cleaned up.

## Single-file vs zip rule

The rule is "readable on iPhone without extra tools". A standalone `SKILL.md` file opens in any markdown viewer. A zip with more files requires unzipping. Therefore:

- **One text file, named `SKILL.md`:** emit as `{name}-SKILL.md`. The recipient renames it to `SKILL.md` and places it in a `{name}/` directory.
- **More than one text file, or the only file has a different name:** zip the entire directory. Binaries, helpers, and example files belong together.

## Output policy

- Output lands alongside the input directory.
- Do not silently overwrite an existing output file. Report and stop if `{name}.zip` or `{name}-SKILL.md` already exists.
- Clean up intermediate directories only if the input is under `/tmp/skill-exports/`.

## Report template

```
## Packaged: {name}

**Input:** {path}
**Format:** single-file | zip
**Output:** {path to .md or .zip}

**Contents:**
- {filename}
- {filename}
- ...

**Cleanup:** intermediate directory removed | source preserved
```

## Composition

```
/export-skill:sanitize say                       # strip PII
/export-skill:package /tmp/skill-exports/say/    # create say.zip or say-SKILL.md
/export-skill:share /tmp/skill-exports/say.zip   # handoff
```
