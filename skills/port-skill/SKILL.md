---
name: port-skill
user-invocable: true
description: Use when porting a Claude Code skill between platforms (macOS, Linux, Windows). Replaces platform-specific commands (say, pbcopy, osascript, brew, etc.) with the target equivalents. Operates on a source skill directory or an already-exported path.
argument-hint: "<skill-name-or-path> <linux|windows|macos>"
allowed-tools:
  - Bash(ls *)
  - Bash(file *)
  - Bash(mkdir -p *)
  - Read(*)
  - Write(**)
---

# Port Skill

Port platform-specifieke commands van een skill naar het doelplatform. De bronbestanden blijven ongemoeid; de geporte versie wordt ernaast geschreven. Geen sanitisatie, geen vertaling: alleen platform-transformatie. Voor sanitisatie zie `sanitize-skill`; voor taalvertaling zie `translate-skill`.

## Invocatie

```
/export-skill:port-skill say linux                          # bron: ~/.claude/skills/say/, doel: Linux
/export-skill:port-skill saysay windows                     # bron: ~/.claude/skills/saysay/, doel: Windows
/export-skill:port-skill /tmp/skill-exports/say/ linux      # bron: geexporteerde directory
/export-skill:port-skill /tmp/skill-exports/say-SKILL.md macos    # bron: los bestand, reverse port naar macOS
```

Eerste argument: skill-naam of pad. Tweede argument: doelplatform (`linux`, `windows`, of `macos`).

## Input-resolutie

- Als het eerste argument geen `/`, `.`, of `~` bevat, interpreteer het als skill-naam en los op naar `~/.claude/skills/<naam>/`.
- Als het een pad is (start met `/`, `./`, of `~`), gebruik het direct. Accepteer zowel directory als los bestand.
- Volg symlinks. Als de bron niet bestaat, meld dit en stop.

## Output-beleid

- **Directory input:** schrijf naar `<bron-parent>/<naam>-<platform>/`. Bij `/tmp/skill-exports/` input, schrijf naast de bron: `/tmp/skill-exports/<naam>-<platform>/`.
- **Los bestand input:** schrijf naast de bron met `.<platform>.md` suffix.
- Overschrijf niets zonder waarschuwing. Als de doellocatie al bestaat, meld dit en stop.

## Stappen

1. **Valideer** bron bestaat en doelplatform is `linux`, `windows`, of `macos`.
2. **Detecteer** bronplatform aan de hand van de gebruikte commands. De meeste skills zijn macOS-first, maar log dit expliciet.
3. **Inventariseer** tekstbestanden in de bron (gebruik `file` voor text/binary detectie).
4. **Port** elk tekstbestand volgens de platform-matrix hieronder. Dit is LLM-werk: vervang commands met hun equivalent, niet met regex.
5. **Kopieer** binaire bestanden as-is; rapporteer ze als overgeslagen.
6. **Schrijf** de geporte versie naar de doellocatie.
7. **Rapporteer** welke commands vervangen zijn en welke handmatige aandacht nodig hebben.

## Platform-matrices

### macOS -> Linux

| macOS | Linux |
|-------|-------|
| `say` | `espeak` / `spd-say` |
| `pbcopy` | `xclip -selection clipboard` / `xsel --clipboard` |
| `pbpaste` | `xclip -selection clipboard -o` |
| `open` | `xdg-open` |
| `osascript` | Geen direct equivalent, beschrijf alternatief |
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
| Shell scripts | PowerShell scripts of WSL notitie |

### Reverse: Linux/Windows -> macOS

Voor reverse ports: gebruik de bovenstaande matrices omgekeerd. Wanneer de bron al (deels) macOS is, log dit en port alleen de niet-macOS delen.

## Port-richtlijnen

- Vervang platform-specifieke commands volgens de matrix. Behoud structuur en logica van het script.
- Wanneer een command geen direct equivalent heeft, voeg een comment toe met uitleg in plaats van stilzwijgend iets te verzinnen.
- Test-instructies en installatiehints aanpassen aan het doelplatform (bijv. `brew install` wordt `apt install`).
- Wanneer een script meerdere platform-specifieke commands gebruikt, overweeg een noot bovenaan met de vereiste packages op het doelplatform.
- SKILL.md frontmatter `description` blijft ongewijzigd; platform wordt niet in de description gezet.

## Rapport template

```
## Port: {naam} -> {platform}

**Bron:** {pad}
**Doel:** {pad}
**Gedetecteerd bronplatform:** {macos|linux|windows|mixed}

### {bestandsnaam}
- Vervangen commands: {lijst van command-paren}
- Handmatige aandacht nodig: {commands zonder direct equivalent}

### Binaries
- {bestandsnaam}: gekopieerd zonder aanpassing
```

## Compositie

```
/export-skill say                                           # sanitiseer + package + share
/export-skill:port-skill /tmp/skill-exports/say/ linux      # port de geexporteerde directory
/export-skill:package-skill /tmp/skill-exports/say-linux/   # herpakketteer naar zip
```

Sanitiseren voor porten is belangrijk als je gaat delen: platform-specifieke paden kunnen zelf PII bevatten (bijv. `/Users/alice/Library/...`).
