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
---

# Sanitize Skill

Strip PII en security-issues uit een skill. De bronbestanden blijven ongemoeid; de gesanitiseerde versie wordt weggeschreven onder `/tmp/skill-exports/<naam>/`. Dit is de enige stap die een skill "veilig om van de machine te halen" maakt.

Voor vertaling zie `translate`. Voor platform-porting zie `port`. Voor inpakken zie `package`.

## Invocatie

```
/export-skill:sanitize say                # bron: ~/.claude/skills/say/
/export-skill:sanitize saysay             # bron: ~/.claude/skills/saysay/
/export-skill:sanitize ./skills/my-skill  # bron: relatief pad
```

Enig argument: skill-naam of pad.

## Input-resolutie

- Als het argument geen `/`, `.`, of `~` bevat, interpreteer het als skill-naam en los op naar `~/.claude/skills/<naam>/`.
- Als het een pad is (start met `/`, `./`, of `~`), gebruik het direct.
- Volg symlinks. Als de bron niet bestaat, meld dit en stop.

## Output-beleid

- Schrijf naar `/tmp/skill-exports/<naam>/`. Maak de directory aan als hij nog niet bestaat.
- Als de doellocatie al bestaat, meld dit en stop zodat de user handmatig kan opruimen.

## Stappen

1. **Valideer** dat de bron bestaat.
2. **Inventariseer** alle bestanden in de directory. Gebruik `file` om per bestand tekst of binary te bepalen.
3. **Sanitiseer** elk tekstbestand volgens de checklist hieronder. Dit is LLM-werk: lees het bestand, analyseer op PII en security issues, en schrijf een schone versie. Geen regex-replace, maar begrip van context.
4. **Kopieer** binaire bestanden as-is naar `/tmp/skill-exports/<naam>/`. Rapporteer een waarschuwing per binair bestand: deze zijn niet op PII gescand.
5. **Rapporteer** per bestand wat er vervangen is en welke security findings er waren.

## Sanitisatie-checklist

### PII-categorieen

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

- Behoud structuur en logica, alleen waarden vervangen.
- Gebruik leesbare generieke equivalenten, niet `[REDACTED]`.
- Wees consistent: dezelfde waarde krijgt overal dezelfde vervanging.
- Wanneer een waarde in meerdere bestanden voorkomt, gebruik dezelfde vervanging.

## Rapport template

```
## Sanitisatie: {naam}

**Bron:** {pad}
**Doel:** /tmp/skill-exports/{naam}/

### {bestandsnaam}

**PII verwijderd:**
- {beschrijving van wat vervangen is}

**Security findings:**
- {beschrijving, of "Geen"}

**Waarschuwingen:**
- {binaries zonder PII-scan, handmatige review suggesties, of "Geen"}
```

Het rapport is bewust gedetailleerd: sanitisatie-findings wijzen vaak op verbeterpunten in de originele skill (hardcoded paden die variabelen hadden moeten zijn, credentials die via een secret manager hadden moeten lopen). Die verbeteringen vallen buiten de scope van deze skill, maar het rapport maakt ze zichtbaar.

## Compositie

```
/export-skill:sanitize say                            # stap 1: strip PII
/export-skill:translate /tmp/skill-exports/say/ en    # stap 2 (optioneel): vertaal
/export-skill:package /tmp/skill-exports/say/         # stap 3: verpak tot .zip of .md
/export-skill:share /tmp/skill-exports/say.zip        # stap 4: handoff met clipboard + Finder
```

Of gebruik de `/export-skill` orchestrator voor de standaard chain.
