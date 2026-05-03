---
name: sanitize
user-invocable: true
description: Use when sanitizing a Claude Code skill: strip PII (home paths, names, internal URLs, credentials, etc.) and flag security issues. Operates on a source skill directory. The single step that makes a skill "safe to leave this machine."
argument-hint: "<skill-name-or-path>"
allowed-tools:
  - Bash(ls *)
  - Bash(file *)
  - Bash(mkdir -p *)
  - Read(*)
  - Write(**)
effort: low
---

# Sanitize Skill

Strip PII and security issues from a skill. Source files remain untouched; the sanitized version is written to `/tmp/skill-exports/<name>/`. This is the only step that makes a skill "safe to leave this machine."

For translation see `translate`. For platform porting see `port`. For packaging see `package`.

## Invocation

```
/export-skill:sanitize say                # source: ~/.claude/skills/say/
/export-skill:sanitize saysay             # source: ~/.claude/skills/saysay/
/export-skill:sanitize ./skills/my-skill  # source: relative path
```

Single argument: skill name or path.

## Input resolution

- If the argument contains no `/`, `.`, or `~`, interpret it as a skill name and resolve to `~/.claude/skills/<name>/`.
- If it is a path (starts with `/`, `./`, or `~`), use it directly.
- Follow symlinks. If the source does not exist, report this and stop.

## Output policy

- Write to `/tmp/skill-exports/<name>/`. Create the directory if it does not yet exist.
- If the destination already exists, report this and stop so the user can clean up manually.

## Steps

1. **Validate** that the source exists.
2. **Inventory** all files in the directory. Use `file` to determine whether each file is text or binary.
3. **Sanitize** each text file according to the checklist below. This is LLM work: read the file, analyze for PII and security issues, and write a clean version. Not regex-replace; this requires context awareness.
4. **Copy** binary files as-is to `/tmp/skill-exports/<name>/`. Report a warning per binary file: these have not been scanned for PII.
5. **Report** per file what was replaced and what security findings there were.

## Sanitization checklist

### PII categories

| Category | Replacement |
|----------|-------------|
| Home directory paths (`/Users/{username}`, `/home/{username}`) | `~` |
| Personal names | Remove or make generic |
| Project/organization names | Generic equivalent (`my-project`, `my-org`) |
| Internal URLs and `.test` domains | `example.test` / `example.com` |
| Email addresses | `user@example.com` |
| Keychain service names and credential references | Make generic |
| GitHub repo paths that identify owner/organization | Make generic (`my-org/my-repo`) |
| Phone numbers, addresses, contact details | Remove |

### Security checks (specific to scripts)

- Hardcoded paths with usernames
- Embedded credentials, tokens, or API keys
- References to internal services
- Environment variable names that leak architecture
- Webhook URLs
- Keychain/credential access patterns

### Replacement system

- Preserve structure and logic, replace values only.
- Use readable generic equivalents, not `[REDACTED]`.
- Be consistent: the same value gets the same replacement everywhere.
- When a value appears in multiple files, use the same replacement.

## Report template

```
## Sanitization: {name}

**Source:** {path}
**Destination:** /tmp/skill-exports/{name}/

### {filename}

**PII removed:**
- {description of what was replaced}

**Security findings:**
- {description, or "None"}

**Warnings:**
- {binaries without PII scan, manual review suggestions, or "None"}
```

The report is deliberately detailed: sanitization findings often point to improvement opportunities in the original skill (hardcoded paths that should have been variables, credentials that should have gone through a secret manager). Those improvements are out of scope for this skill, but the report makes them visible.

## Composition

```
/export-skill:sanitize say                            # step 1: strip PII
/export-skill:translate /tmp/skill-exports/say/ en    # step 2 (optional): translate
/export-skill:package /tmp/skill-exports/say/         # step 3: bundle to .zip or .md
/export-skill:share /tmp/skill-exports/say.zip        # step 4: handoff with clipboard + Finder
```

Or use the `/export-skill` orchestrator for the standard chain.
