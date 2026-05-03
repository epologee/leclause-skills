---
name: share
user-invocable: true
description: Use when handing off a packaged skill to the user for sharing. Writes a short sharing summary, stashes it for /clipboard, opens the parent directory in Finder, and prints a report. macOS-only handoff.
argument-hint: "<file-or-dir-path>"
allowed-tools:
  - Bash(ls *)
  - Bash(open *)
  - Read(*)
  - Write(**)
effort: low
---

# Share Skill

Hand a packaged skill off to the user so they can send it directly. Opens the parent directory in Finder, prints the export report first, and closes with a short summary so a subsequent `/clipboard` copies only that summary.

macOS-only: uses `open` for Finder. On Linux/Windows this requires a port (see `port`).

## Invocation

```
/export-skill:share /tmp/skill-exports/say-SKILL.md  # single-file export
/export-skill:share /tmp/skill-exports/say/          # directory (source for summary)
```

Single argument: path to a directory containing `SKILL.md` or to a standalone `*-SKILL.md` file. Zip files are not read (no unzip tool); invoke this skill before packaging, or point to the source directory.

## Steps

1. **Validate** that the path exists and contains a `SKILL.md` (or is itself a `*-SKILL.md`).
2. **Read** the `SKILL.md` to understand the skill.
3. **Write summary:** generate a concise summary in the language of the SKILL.md body text you just read. For a normal export that is the source language; for a translated export it is the target language; in both cases it is the language the recipient sees. The summary is intended for colleagues, online posts, or a chat message.
   - What the skill does (1 to 2 sentences)
   - How to invoke it
   - The main features/steps (concise list)
   - Any requirements or limitations
   - No PII, no sanitization details, no report information
4. **Print the summary as the last substantive reply:** the chain call to this skill must end with the summary as the only output, so that a subsequent `/clipboard` call copies only the summary. No meta-text, no report headers after the summary.
5. **Open in Finder:** `open {parent-dir}` so the user can drag or email the file directly. This happens before the summary so Finder does not overwrite the last generated text.
6. **Report** the path and location separately, above the summary.

## Summary guidelines

The summary is explicitly different from the sanitization report:

- **Sanitization report** (from `sanitize`) is detailed: what was replaced, which security findings, which binaries. For the user themselves.
- **Summary** (from this skill) is shareable: what the skill does and how it works. For recipients.

Keep the summary under 10 lines. Inline formatting with backticks for commands and filenames.

## Report template

The last line of the output must be the last line of the summary. No trailing "next step" line, no closing header, no meta-text after the summary: `/clipboard` copies text from the last reply and anything after the summary would end up in it.

```
## Ready to share: {name}

**File:** {path}
**Type:** single-file-md | directory

**Finder opened at:** {parent-dir}

Drag the file from Finder to your chat/mail, or use `/clipboard` to paste the summary below.

---

{the summary as generated, ending on the last substantive line}
```

## Composition

```
/export-skill:sanitize say                       # strip PII, output /tmp/skill-exports/say/
/export-skill:package /tmp/skill-exports/say/    # zip or md
/export-skill:share /tmp/skill-exports/say/      # summary + Finder (point to the dir, not the zip)
```

Or use the `/export-skill` orchestrator for the complete chain.
