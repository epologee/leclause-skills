---
name: share-skill
user-invocable: true
description: Use when handing off a packaged skill to the user for sharing. Writes a short sharing summary, stashes it for /clipboard, opens the parent directory in Finder, and prints a report. macOS-only handoff.
argument-hint: "<file-or-dir-path>"
allowed-tools:
  - Bash(ls *)
  - Bash(open *)
  - Read(*)
  - Write(**)
---

# Share Skill

Hand een verpakte skill over aan de user zodat die hem direct kan versturen. Schrijft een korte samenvatting, zet hem klaar voor `/clipboard`, opent de parent-directory in Finder, en print een rapport.

macOS-only: gebruikt `open` voor Finder. Op Linux/Windows vereist dit een port (zie `port-skill`).

## Invocatie

```
/export-skill:share-skill /tmp/skill-exports/say.zip       # zip-export
/export-skill:share-skill /tmp/skill-exports/say-SKILL.md  # single-file export
/export-skill:share-skill /tmp/skill-exports/say/          # losse directory (zonder voorafgaand packagen)
```

Enig argument: pad naar het bestand of de directory die gedeeld moet worden.

## Stappen

1. **Valideer** dat het pad bestaat.
2. **Lees** de SKILL.md (of, bij een zip, het hoofdbestand in de zip als dat kan; anders overslaan) om de skill te begrijpen.
3. **Schrijf samenvatting:** genereer een beknopte samenvatting, in de taal van de skill (niet de doeltaal van een eventuele vertaling). De samenvatting is bedoeld voor collega's, online posts, of een chatbericht.
   - Wat de skill doet (1 tot 2 zinnen)
   - Hoe je hem aanroept
   - De belangrijkste features/stappen (beknopte lijst)
   - Eventuele vereisten of beperkingen
   - Geen PII, geen sanitisatie-details, geen rapport-informatie
4. **Stash voor clipboard:** sla de samenvatting op als het "laatste inhoudelijke antwoord" zodat een opvolgende `/clipboard` alleen deze samenvatting kopieert, zonder dit rapport zelf.
5. **Open in Finder:** `open {parent-dir}` zodat de user het bestand direct kan slepen of mailen.
6. **Rapporteer:** print het export-rapport met bestand-pad en de samenvatting die klaar staat.

## Samenvattings-richtlijnen

De samenvatting is expliciet verschillend van het sanitisatie-rapport:

- **Sanitisatie-rapport** (van `sanitize-skill`) is gedetailleerd: wat is vervangen, welke security findings, welke binaries. Voor de user zelf.
- **Samenvatting** (van deze skill) is deelbaar: wat doet de skill en hoe werkt hij. Voor ontvangers.

Houd de samenvatting onder 10 regels. Inline formatting met backticks voor commando's en bestandsnamen.

## Rapport template

```
## Klaar om te delen: {naam}

**Bestand:** {pad}
**Type:** zip | single-file-md | directory

**Finder geopend op:** {parent-dir}

### Samenvatting (klaar voor /clipboard)

{de samenvatting zoals gegenereerd}

**Volgende stap:** sleep het bestand uit Finder in je chat/mail, of gebruik /clipboard om de samenvatting te plakken.
```

## Compositie

```
/export-skill:sanitize-skill say                       # strip PII
/export-skill:package-skill /tmp/skill-exports/say/    # zip of md
/export-skill:share-skill /tmp/skill-exports/say.zip   # samenvatting + Finder
```

Of gebruik de `/export-skill` orchestrator voor de complete chain.
