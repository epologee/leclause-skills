---
name: port
user-invocable: true
description: Use when porting a Claude Code skill between platforms (macOS, Linux, Windows). Replaces platform-specific commands (say, pbcopy, osascript, brew, etc.) with the target equivalents. Operates on a source skill directory or an already-exported path.
argument-hint: "<skill-name-or-path> <linux|windows|macos>"
allowed-tools:
  - Bash(ls *)
  - Bash(file *)
  - Bash(mkdir -p *)
  - Read(*)
  - Write(**)
effort: low
---

# Port Skill

Port platform-specific commands of a skill to the target platform. Source files remain untouched; the ported version is written alongside them. No sanitization, no translation: only platform transformation. For sanitization see `sanitize`; for language translation see `translate`.

## Invocation

```
/export-skill:port say linux                          # source: ~/.claude/skills/say/, target: Linux
/export-skill:port saysay windows                     # source: ~/.claude/skills/saysay/, target: Windows
/export-skill:port /tmp/skill-exports/say/ linux      # source: exported directory
/export-skill:port /tmp/skill-exports/say-SKILL.md macos    # source: standalone file, reverse port to macOS
```

First argument: skill name or path. Second argument: target platform (`linux`, `windows`, or `macos`).

## Input resolution

- If the first argument contains no `/`, `.`, or `~`, interpret it as a skill name and resolve to `~/.claude/skills/<name>/`.
- If it is a path (starts with `/`, `./`, or `~`), use it directly. Accept both directory and standalone file.
- Follow symlinks. If the source does not exist, report this and stop.

## Output policy

- **Directory input:** write to `<source-parent>/<name>-<platform>/`. For `/tmp/skill-exports/` input, write alongside the source: `/tmp/skill-exports/<name>-<platform>/`.
- **Standalone file input:** write alongside the source with `.<platform>.md` suffix.
- Never overwrite without warning. If the destination already exists, report this and stop.

## Steps

1. **Validate** source exists and target platform is `linux`, `windows`, or `macos`.
2. **Detect** source platform based on the commands used. Most skills are macOS-first, but log this explicitly.
3. **Inventory** text files in the source (use `file` for text/binary detection).
4. **Port** each text file according to the platform matrix below. This is LLM work: replace commands with their equivalents, not via regex.
5. **Copy** binary files as-is; report them as skipped.
6. **Write** the ported version to the destination.
7. **Report** which commands were replaced and which need manual attention.

## Platform matrices

### macOS -> Linux

| macOS | Linux |
|-------|-------|
| `say` | `espeak` / `spd-say` |
| `pbcopy` | `xclip -selection clipboard` / `xsel --clipboard` |
| `pbpaste` | `xclip -selection clipboard -o` |
| `open` | `xdg-open` |
| `osascript` | No direct equivalent, describe alternative |
| `screencapture` | `scrot` / `gnome-screenshot` |
| macOS Keychain (`security`) | `secret-tool` (GNOME Keyring) / `pass` |
| `NSPasteboard` | X11/Wayland clipboard APIs |
| `~/Library/...` | `~/.config/...` / `~/.local/share/...` (XDG) |
| `brew install` | `apt install` / `dnf install` |
| `launchctl` | `systemctl` |
| `-f avfoundation` (ffmpeg) | `-f x11grab` / `-f pulse` |

### macOS -> Windows

| macOS | Windows |
|-------|---------|
| `say` | PowerShell `SpeechSynthesizer` |
| `pbcopy` | `clip.exe` / `Set-Clipboard` |
| `open` | `start` / `Invoke-Item` |
| `osascript` | PowerShell |
| macOS Keychain | Windows Credential Manager (`cmdkey`) |
| `~/Library/...` | `$env:APPDATA\...` |
| Shell scripts | PowerShell scripts or WSL note |

### Reverse: Linux/Windows -> macOS

For reverse ports: use the matrices above in reverse. When the source is already (partially) macOS, log this and port only the non-macOS parts.

## Porting guidelines

- Replace platform-specific commands according to the matrix. Preserve the structure and logic of the script.
- When a command has no direct equivalent, add a comment with an explanation rather than silently inventing something.
- Adjust test instructions and install hints to the target platform (e.g. `brew install` becomes `apt install`).
- When a script uses multiple platform-specific commands, consider adding a note at the top with the required packages on the target platform.
- SKILL.md frontmatter `description` remains unchanged; platform is not added to the description.

## Report template

```
## Port: {name} -> {platform}

**Source:** {path}
**Destination:** {path}
**Detected source platform:** {macos|linux|windows|mixed}

### {filename}
- Replaced commands: {list of command pairs}
- Manual attention needed: {commands without direct equivalent}

### Binaries
- {filename}: copied without modification
```

## Composition

```
/export-skill:sanitize say                            # strip PII, output /tmp/skill-exports/say/
/export-skill:port /tmp/skill-exports/say/ linux      # port the sanitized directory
/export-skill:package /tmp/skill-exports/say-linux/   # zip or md
```

Or use the orchestrator in one step: `/export-skill say linux` does sanitize + port + package + share.

Sanitizing before porting matters when sharing: platform-specific paths can themselves contain PII (e.g. `/Users/alice/Library/...`).
