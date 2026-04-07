---
name: export-skill
description: Use when the user wants to export/share a skill with others, stripping private information and checking for security issues. Supports optional translation (en/nl) and platform porting (linux/windows).
args: "<skill-name> [en|nl|linux|windows]"
allowed-tools:
  - Bash(zip *)
  - Bash(rm -rf /tmp/skill-exports/*)
  - Bash(mkdir -p /tmp/skill-exports/*)
  - Bash(ls *)
  - Bash(file *)
  - Bash(open *)
  - Read(*)
  - Write(/tmp/skill-exports/**)
---

# Export Skill

Exporteer een skill uit `~/.claude/skills/` als gesanitiseerd bestand, klaar om te delen. Skills met alleen een SKILL.md worden een los `.md` bestand (leesbaar op iPhone). Skills met meerdere bestanden worden een zip.

## Invocatie

```
/export-skill say              # sanitiseer alleen
/export-skill say en           # sanitiseer + vertaal naar Engels
/export-skill say nl           # sanitiseer + vertaal naar Nederlands
/export-skill say linux        # sanitiseer + port naar Linux
/export-skill say windows      # sanitiseer + port naar Windows
```

Eerste argument: naam van een skill-directory in `~/.claude/skills/`.
Tweede argument (optioneel): doeltaal (`en`/`nl`) of doelplatform (`linux`/`windows`).

## Stappen

### 1. Valideer

Controleer dat `~/.claude/skills/{name}/` bestaat (volg symlinks). Als de directory niet bestaat, meld dit en stop.

### 2. Inventariseer

Lees alle bestanden in de directory. Gebruik `file` om per bestand te bepalen of het tekst of binair is.

### 3. Sanitiseer tekstbestanden

Lees elk tekstbestand en pas de sanitisatie-checklist toe (zie hieronder). Schrijf de gesanitiseerde versie naar `/tmp/skill-exports/{name}/` (bij meerdere bestanden) of direct als `/tmp/skill-exports/{name}-SKILL.md` (bij alleen een SKILL.md).

**Dit is LLM-werk.** Lees het bestand, analyseer de inhoud op PII en security issues, en schrijf een schone versie. Geen regex-replace, maar begrip van context.

### 3b. Vertaal of port (optioneel)

Als er een tweede argument is meegegeven, transformeer de gesanitiseerde bestanden. Volgorde is altijd: eerst sanitiseren, dan transformeren.

**Bij taalargument (`en`/`nl`):** Vertaal de gesanitiseerde bestanden naar de doeltaal. Volg de vertaalregels hieronder.

**Bij platformargument (`linux`/`windows`):** Port de gesanitiseerde bestanden naar het doelplatform. Gebruik de platform-port matrices hieronder.

### 4. Binaries

Kopieer binaire bestanden as-is naar `/tmp/skill-exports/{name}/`. Rapporteer een waarschuwing per binair bestand: deze konden niet gescand worden op PII.

### 5. Verpak

**Eén bestand (alleen SKILL.md):** Schrijf de gesanitiseerde SKILL.md direct als `/tmp/skill-exports/{name}-SKILL.md`. Geen zip, geen tussenliggende directory. De ontvanger renamed het bestand naar `SKILL.md` en plaatst het in een `{name}/` directory.

**Meerdere bestanden:**

```bash
cd /tmp/skill-exports && zip -r {name}.zip {name}/
```

De zip bevat de directory `{name}/` met alle bestanden erin. Ruim daarna de tussenliggende directory op:

```bash
rm -rf /tmp/skill-exports/{name}/
```

### 6. Samenvatting schrijven

Schrijf een beknopte samenvatting van wat de skill doet, in de taal van de skill (niet de doeltaal van een eventuele vertaling). Deze samenvatting is bedoeld om te delen met collega's of online. Bewaar deze als het "laatste inhoudelijke antwoord" zodat een opvolgende `/clipboard` alleen deze samenvatting kopieert, zonder het sanitisatie-rapport.

De samenvatting beschrijft:
- Wat de skill doet (1-2 zinnen)
- Hoe je hem aanroept
- De belangrijkste features/stappen (als beknopte lijst)
- Eventuele vereisten of beperkingen

Geen PII, geen sanitisatie-details, geen rapport-informatie in de samenvatting.

### 7. Rapporteer

Print het rapport (zie template hieronder).

## Sanitisatie-checklist

### PII-categorieën

| Categorie | Vervanging |
|-----------|-----------|
| Home directory paden (`/Users/{username}`, `/home/{username}`) | `~` |
| Persoonlijke namen | Verwijderen of generiek maken |
| Project/organisatienamen | Generiek equivalent (`my-project`, `my-org`) |
| Interne URLs en `.test` domeinen | `example.test` / `example.com` |
| Email adressen | `user@example.com` |
| Keychain service names en credential-referenties | Generiek maken |
| GitHub repo paden die eigenaar/organisatie identificeren | Generiek maken (`my-org/my-repo`) |
| Telefoonnummers, adressen, contactgegevens | Verwijderen |

### Security checks (specifiek voor scripts)

- Hardcoded paden met gebruikersnamen
- Embedded credentials, tokens, of API keys
- Referenties naar interne services
- Environment variable namen die architectuur lekken
- Webhook URLs
- Keychain/credential access patterns

### Vervangsysteem

- Behoud structuur en logica, alleen waarden vervangen
- Gebruik leesbare generieke equivalenten, niet `[REDACTED]`
- Wees consistent: dezelfde waarde krijgt overal dezelfde vervanging
- Wanneer een waarde in meerdere bestanden voorkomt, gebruik dezelfde vervanging

## Rapport template

Na het wegschrijven, print:

```
## Export: {name}

**Bestand:** `/tmp/skill-exports/{name}-SKILL.md`
(of bij meerdere bestanden)
**Zip:** `/tmp/skill-exports/{name}.zip`

**Bestanden:**
- {name}/SKILL.md
- {name}/other-file
- ...

## Sanitisatie-samenvatting

### {bestandsnaam}

**PII verwijderd:**
- {beschrijving van wat er vervangen is}

**Security findings:**
- {beschrijving van findings, of "Geen"}

**Waarschuwingen:**
- {binaries, handmatige review suggesties, of "Geen"}
```

### Stap 8: Open in Finder

Na het rapport, open de export-map zodat de user het bestand direct kan versturen:

```bash
open /tmp/skill-exports/
```

De samenvatting is bewust gedetailleerd: sanitisatie-findings wijzen vaak op verbeterpunten in de originele skill (hardcoded paden die variabelen hadden moeten zijn, credentials die via een secret manager hadden moeten lopen). Die verbeteringen vallen buiten de scope van deze skill, maar de samenvatting maakt ze zichtbaar.

## Vertaalregels

Gelden wanneer het tweede argument een taal is (`en`/`nl`).

### Wat vertalen

- SKILL.md body tekst (beschrijvingen, instructies, voorbeelden)
- Comments in scripts
- Usage strings en help tekst
- Voorbeeld-output

### Wat NIET vertalen

- Frontmatter `name` en `description` (altijd Engels)
- Code (variabelen, functies, commands)
- Technische termen die onnatuurlijk klinken in de doeltaal
- Bestandsnamen

## Platform-port matrices

Gelden wanneer het tweede argument een platform is (`linux`/`windows`).

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

### Port-richtlijnen

- Vervang platform-specifieke commands volgens de matrix
- Wanneer een command geen direct equivalent heeft, voeg een comment toe met uitleg
- Behoud de structuur en logica van het script
- Test-instructies aanpassen aan het doelplatform (bijv. `brew install` -> `apt install`)
- Wanneer een script meerdere platform-specifieke commands gebruikt, overweeg een noot bovenaan over vereiste packages

## Uitgebreid rapport template

Wanneer er een tweede argument is meegegeven, voeg deze secties toe aan het rapport:

```
## Vertaling (bij taalargument)

**Doeltaal:** {en|nl}

### {bestandsnaam}
- {beschrijving van vertaalde secties}
- **Onvertaald gelaten:** {technische termen, code, frontmatter}

## Platform-port (bij platformargument)

**Doelplatform:** {linux|windows}

### {bestandsnaam}
- {beschrijving van geporte commands}
- **Handmatige aandacht nodig:** {commands zonder direct equivalent}
```
