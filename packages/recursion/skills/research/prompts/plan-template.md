# Plan Template

Canonical schema voor plan-bestanden in `~/.claude/recursion/plans/`. Single source of truth, gedeeld door `recursion` (leest `status` bij reject) en `research` (schrijft nieuwe plannen).

## Bestandsnaam

`YYYY-MM-DD-korte-beschrijving.md`

Voorbeeld: `2026-03-25-hook-test-coverage-check.md`

## Frontmatter velden

| Veld | Mogelijke waarden | Schrijver |
|------|-------------------|-----------|
| `status` | `proposed`, `rejected`, `implemented` | `research` (proposed bij schrijven), `recursion` (rejected bij /recursion reject) |
| `datum` | `YYYY-MM-DD` | `research` |
| `categorie` | `skill`, `claude-md`, `hook`, `setting`, `structural` | `research` |
| `impact` | `high`, `medium`, `low` | `research` |
| `confidence` | `robuust`, `waarschijnlijk`, `fragiel` | `research` |

## Body template

```markdown
# [Titel: wat verandert er]

status: proposed
datum: YYYY-MM-DD
categorie: [skill | claude-md | hook | setting | structural]
impact: [high | medium | low]
confidence: [robuust | waarschijnlijk | fragiel]

## Wat

Concrete beschrijving. Welke bestanden wijzigen? Wat is het
eindresultaat? Wees specifiek: "Voeg iOS-specifieke test guidance
toe aan testing-philosophy" is een plan, "verbeter testing" niet.

## Waarom

De belangrijkste sectie. Concrete scenario's, frequentie van het
probleem, kwantificering waar mogelijk. Als de waarom niet
overtuigt, is het plan niet sterk genoeg.

## Bron

URL's naar blog posts, issues, discussies. Of interne observatie
met verwijzing naar concreet bestand/regel. Meerdere bronnen
versterken het plan. Eén bron is het minimum.

## Wie doet dit nog meer

Concrete voorbeelden met URLs. Per referentie: wie (naam/handle),
wat (hun implementatie), en waar (link naar repo, blog, of
discussie). Geen vage verwijzingen ("sommige developers doen dit"),
alleen verifieerbare referenties. Minimaal 1, bij voorkeur 2-3.
Als echt niemand dit doet: beschrijf expliciet waarom dit een
gat is dat nog niet gevuld is, niet een idee dat niemand nodig heeft.

## Auto-loop context

### Doel
[1-2 zinnen: wat moet de auto-loop bereiken]

### Bestanden die wijzigen
- `pad/naar/bestand`: [wat verandert]

### Stappen
1. [concrete stap met verwacht resultaat]
2. ...

### Verificatie
- [hoe verifieer je dat het werkt]

### Scope-begrenzing
- [wat valt NIET binnen dit plan]
- [wanneer is de auto-loop KLAAR]
```

## Kwaliteitseisen

Elk plan moet voldoen aan:

1. **Atomair**: implementeerbaar in één auto-loop sessie
2. **Self-contained**: auto-loop context bevat alles om te starten
3. **Overtuigend**: waarom-sectie laat geen twijfel
4. **Verifieerbaar**: concrete check of het werkt
5. **Afgebakend**: scope-begrenzing voorkomt creep

Te grote verbeteringen: splits in meerdere plannen met volgorde.

## Status transities

```
(nieuw) --research schrijft--> proposed
proposed --recursion reject--> rejected (plus blocklist toevoeging)
proposed --user implementeert via /auto-loop--> implemented
```

`research` schrijft alleen `proposed`. De status-transities `rejected` en `implemented` zijn eigendom van de orchestrator resp. de user.
