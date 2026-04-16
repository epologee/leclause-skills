---
name: package-skill
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
---

# Package Skill

Verpak een skill-directory tot een transporteerbare vorm. Mechanisch werk: een directory met alleen `SKILL.md` wordt een los `.md` bestand (leesbaar op iPhone zonder unzip). Een directory met meerdere bestanden wordt een `.zip`.

Geen content-transformatie: deze skill verandert de tekst niet. Voor sanitisatie zie `sanitize-skill`, voor vertaling `translate-skill`, voor porting `port-skill`.

## Invocatie

```
/export-skill:package-skill /tmp/skill-exports/say/            # directory met meerdere bestanden -> say.zip
/export-skill:package-skill /tmp/skill-exports/say-en/         # translated directory -> say-en.zip
/export-skill:package-skill ~/.claude/skills/saysay/           # directory met alleen SKILL.md -> saysay-SKILL.md
```

Enig argument: pad naar de directory die je wilt verpakken.

## Stappen

1. **Valideer** dat het argument een bestaande directory is.
2. **Tel** de tekstbestanden in de directory (gebruik `file`).
3. **Beslis format:**
   - Precies een tekstbestand, en dat bestand heet `SKILL.md`: emit `{parent}/{naam}-SKILL.md` door de SKILL.md directly te kopieren met de nieuwe naam.
   - Anders: maak een zip.
4. **Als zip:** run `cd {parent} && zip -r {naam}.zip {naam}/`. Daarna kan de intermediate directory weg, maar doe dat ALLEEN als de input onder `/tmp/skill-exports/` staat. Bronnen buiten die locatie nooit verwijderen.
5. **Rapporteer** het resulterende bestand en of de intermediate directory is opgeruimd.

## Single-file vs zip regel

De regel is "leesbaar op iPhone zonder extra tools". Een los `SKILL.md` bestand opent in elke markdown viewer. Een zip met meer bestanden vereist unzippen. Daarom:

- **Een tekstbestand, heet `SKILL.md`:** emit als `{naam}-SKILL.md`. De ontvanger renamed naar `SKILL.md` en plaatst in een `{naam}/` directory.
- **Meer dan een tekstbestand, of het enige bestand heet anders:** zip de hele directory. Binaries, helpers, voorbeeld-bestanden horen bij elkaar.

## Output-beleid

- Output landt naast de input-directory.
- Overschrijf een bestaand output-bestand niet stilzwijgend. Meld en stop als `{naam}.zip` of `{naam}-SKILL.md` al bestaat.
- Ruim intermediate directories alleen op als de input onder `/tmp/skill-exports/` staat.

## Rapport template

```
## Verpakt: {naam}

**Input:** {pad}
**Format:** single-file | zip
**Output:** {pad naar .md of .zip}

**Inhoud:**
- {bestandsnaam}
- {bestandsnaam}
- ...

**Opruim:** intermediate directory verwijderd | bron behouden
```

## Compositie

```
/export-skill:sanitize-skill say                       # strip PII
/export-skill:package-skill /tmp/skill-exports/say/    # maak say.zip of say-SKILL.md
/export-skill:share-skill /tmp/skill-exports/say.zip   # handoff
```
