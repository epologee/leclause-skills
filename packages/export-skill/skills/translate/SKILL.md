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

Vertaal de tekst van een skill tussen Nederlands en Engels. De bronbestanden blijven ongemoeid; de vertaalde versie wordt ernaast geschreven. Geen sanitisatie, geen porting: alleen taaltransformatie. Voor sanitisatie zie `sanitize`; voor platform-porting zie `port`.

## Invocatie

```
/export-skill:translate say en                        # bron: ~/.claude/skills/say/, doel: Engels
/export-skill:translate saysay nl                     # bron: ~/.claude/skills/saysay/, doel: Nederlands
/export-skill:translate /tmp/skill-exports/say/ en    # bron: geexporteerde directory
/export-skill:translate /tmp/skill-exports/say-SKILL.md en   # bron: los bestand
```

Eerste argument: skill-naam of pad. Tweede argument: doeltaal (`en` of `nl`).

## Input-resolutie

- Als het eerste argument geen `/`, `.`, of `~` bevat, interpreteer het als skill-naam en los op naar `~/.claude/skills/<naam>/`.
- Als het een pad is (start met `/`, `./`, of `~`), gebruik het direct. Accepteer zowel directory als los bestand.
- Volg symlinks. Als de bron niet bestaat, meld dit en stop.

## Output-beleid

- **Directory input:** schrijf naar `<bron-parent>/<naam>-<taal>/` (bijv. `~/.claude/skills/say-en/`). Bij `/tmp/skill-exports/` input, schrijf naast de bron: `/tmp/skill-exports/<naam>-<taal>/`.
- **Los bestand input:** schrijf naast de bron met `.<taal>.md` suffix (bijv. `/tmp/skill-exports/say-SKILL.en.md`).
- Overschrijf niets zonder waarschuwing. Als de doellocatie al bestaat, meld dit en stop (user kan handmatig opruimen).

## Stappen

1. **Valideer** bron bestaat en doeltaal is `en` of `nl`.
2. **Inventariseer** tekstbestanden in de bron (gebruik `file` voor text/binary detectie).
3. **Vertaal** elk tekstbestand volgens de vertaalregels hieronder. Dit is LLM-werk, geen regex-replace.
4. **Kopieer** binaire bestanden as-is; rapporteer ze als overgeslagen.
5. **Schrijf** de vertaalde versie naar de doellocatie.
6. **Rapporteer** wat vertaald is en wat onvertaald gelaten is.

## Vertaalregels

### Wat vertalen

- SKILL.md body tekst (beschrijvingen, instructies, voorbeelden)
- Comments in scripts
- Usage strings en help tekst
- Voorbeeld-output
- Section headers in Markdown (behalve waar de kop een technische term is)

### Wat NIET vertalen

- Frontmatter `name` en `description` (altijd Engels; deze zijn ook het kanaal waarover skill-activatie loopt)
- Code (variabelen, functies, commands, shell snippets, JSON/YAML waarden)
- Technische termen die onnatuurlijk klinken in de doeltaal (bijv. "commit", "repository", "prompt")
- Bestandsnamen en paden
- URL's
- Stringwaarden in code-blokken (tenzij het duidelijk UI-tekst is die de user ziet)

### Consistentie

- Dezelfde bron-term krijgt dezelfde vertaling in alle bestanden van dezelfde skill.
- Bij twijfel tussen een technische en een Nederlandse term: kies de Nederlandse variant alleen als die gangbaar is onder ontwikkelaars.
- Toon en register blijven consistent met het origineel (informeel blijft informeel, imperatief blijft imperatief).

## Rapport template

```
## Vertaling: {naam} -> {taal}

**Bron:** {pad}
**Doel:** {pad}

### {bestandsnaam}
- Vertaald: {beknopte beschrijving van de secties}
- Onvertaald gelaten: {technische termen, code-blokken, frontmatter}

### Binaries
- {bestandsnaam}: gekopieerd zonder aanpassing
```

## Compositie

Deze skill doet een ding. Voor een volledige export-flow chain je hem met andere skills:

```
/export-skill:sanitize say                            # strip PII, output /tmp/skill-exports/say/
/export-skill:translate /tmp/skill-exports/say/ en    # vertaal de gesanitiseerde directory
/export-skill:package /tmp/skill-exports/say-en/      # zip of md
```

Of gebruik de orchestrator in een stap: `/export-skill say en` doet sanitize + translate + package + share.

De volgorde sanitiseren-voor-transformeren is belangrijk: transformeren van een ongesanitiseerd bestand lekt PII in de vertaling.
