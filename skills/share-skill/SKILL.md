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

Hand een verpakte skill over aan de user zodat die hem direct kan versturen. Opent de parent-directory in Finder, print eerst het export-rapport, en sluit af met een korte samenvatting zodat een opvolgende `/clipboard` alleen die samenvatting kopieert.

macOS-only: gebruikt `open` voor Finder. Op Linux/Windows vereist dit een port (zie `port-skill`).

## Invocatie

```
/export-skill:share-skill /tmp/skill-exports/say-SKILL.md  # single-file export
/export-skill:share-skill /tmp/skill-exports/say/          # directory (bron voor samenvatting)
```

Enig argument: pad naar een directory met `SKILL.md` of naar een los `*-SKILL.md` bestand. Zip-bestanden worden niet gelezen (geen unzip-tool); roep deze skill aan voor het packagen, of wijs naar de bron-directory.

## Stappen

1. **Valideer** dat het pad bestaat en een `SKILL.md` bevat (of zelf een `*-SKILL.md` is).
2. **Lees** de `SKILL.md` om de skill te begrijpen.
3. **Schrijf samenvatting:** genereer een beknopte samenvatting, in de taal van de skill (niet de doeltaal van een eventuele vertaling). De samenvatting is bedoeld voor collega's, online posts, of een chatbericht.
   - Wat de skill doet (1 tot 2 zinnen)
   - Hoe je hem aanroept
   - De belangrijkste features/stappen (beknopte lijst)
   - Eventuele vereisten of beperkingen
   - Geen PII, geen sanitisatie-details, geen rapport-informatie
4. **Print de samenvatting als laatste inhoudelijke antwoord:** de chain-call van deze skill moet eindigen met de samenvatting als enige output, zodat een opvolgende `/clipboard` aanroep alleen de samenvatting kopieert. Geen meta-tekst, geen rapport-headers na de samenvatting.
5. **Open in Finder:** `open {parent-dir}` zodat de user het bestand direct kan slepen of mailen. Dit gebeurt voor de samenvatting zodat Finder niet de laatst-gegenereerde tekst overschrijft.
6. **Rapporteer** het pad en de locatie apart, boven de samenvatting.

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
