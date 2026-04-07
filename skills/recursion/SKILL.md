---
name: recursion
description: >
  Use when improving the Claude Code workflow through deep research.
  Triggers on /recursion, "wat kunnen we verbeteren", "workflow
  improvements", or scheduled daily runs. Produces atomic improvement
  plans with full motivation.
argument-hint: "[now | on | off | status | focus <thema> | reject <file>]"
allowed-tools:
  - Bash(date *)
  - Bash(stat *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Bash(rm *)
  - Bash(git -C ~/.claude *)
  - Edit(~/.claude/**)
  - Write(~/.claude/**)
  - Read(~/.claude/**)
  - Glob(~/.claude/**)
  - Grep(~/.claude/**)
  - WebSearch
  - WebFetch(*)
  - Agent
  - CronCreate
  - CronDelete
  - RemoteTrigger
---

# Recursion

Dagelijkse deep research die kant-en-klare improvement plannen produceert
voor de Claude Code werkwijze. Geen executie, alleen research en plannen.
De user beslist welke plannen worden opgepakt.

## Kernprincipe

Recursion is een research machine, geen executor. Het produceert plannen
die zo overtuigend en compleet zijn dat de beslissing om ze te
implementeren vanzelfsprekend wordt. Elke verbetering is een atomair
plan: klein genoeg om in één auto-loop sessie te implementeren, groot
genoeg om merkbaar verschil te maken.

**Na de research stopt alles.** De user beslist 's ochtends welke plannen
worden goedgekeurd. Goedgekeurde plannen worden opgepakt met `/auto-loop`.
Over tijd bouwt de plans directory een database van improvement ideeën.

## Subcommando's

| Argument | Actie |
|----------|-------|
| _(geen)_ | Eenmalige run vannacht om 1:03 (session-only) |
| `now` | Direct starten in huidige sessie |
| `on` | Permanente nachtelijke schedule (via RemoteTrigger) |
| `off` | Schedule stoppen |
| `status` | Toon state, actieve plannen, schedule |
| `focus <thema>` | Thematisch filter instellen |
| `focus off` | Terug naar brede verkenning |
| `reject <bestand>` | Markeer plan als rejected, voeg toe aan blocklist |

### `/recursion` (eenmalig vannacht)

1. Bereken cron voor vannacht 1:03: `3 1 <dag> <maand> *`
2. CronCreate met `recurring: false` en de run prompt
3. Waarschuw: session-only, verdwijnt als sessie sluit

### `/recursion now`

1. Lees `~/.claude/recursion/state.md`
2. Voer de volledige research workflow uit (zie hieronder)

### `/recursion on` / `off`

Gebruik RemoteTrigger via de `/schedule` skill. Cron: `3 1 * * *`.
Sla trigger ID op in state.md als `schedule_id`.

### `/recursion status`

Toon: laatste run, total_runs, focus thema, schedule actief,
en een overzicht van plannen per status (proposed/rejected/implemented).

### `/recursion reject <bestand>`

1. Lees het plan in `~/.claude/recursion/plans/<bestand>`
2. Wijzig `status: proposed` naar `status: rejected`
3. Voeg toe aan `~/.claude/recursion/blocklist.md` met datum en reden
4. Meld wat afgewezen en geblocklist is

### `/recursion focus <thema>` / `focus off`

Schrijf thema naar state.md. Volgende run prioriteert dit thema.

## Research Workflow

Vier stappen, synchroon in één sessie.

```
PREPARE → RESEARCH → PLAN → NOTIFY → STOP
```

### 1. PREPARE

1. Haal datum op: `date +%Y-%m-%d`
2. Lees `~/.claude/recursion/state.md`
3. Lees `~/.claude/recursion/blocklist.md`
4. Scan bestaande plannen: `ls ~/.claude/recursion/plans/*.md`
5. Update state: `last_run`, `total_runs + 1`

### 2. RESEARCH

Dit is het hart. Grondig, radicaal, geen concessies. Spawn parallelle
agents voor elke research-richting.

#### Spoor A: Friction Analysis (parallel met externe research)

Spawn een Opus agent met de prompt uit `${CLAUDE_SKILL_DIR}/prompts/friction-analysis.md`.
Analyseert sessie-JSONLs sinds vorige run op friction patronen:
correcties, overclaimed confidence, compliance reflex, premature action,
doel-abandonment, downgrade-spiralen, herhaalde instructies,
self-improvement audit.

#### Spoor B: Externe Research (5-10 parallelle agents)

Lees `${CLAUDE_SKILL_DIR}/prompts/explore.md` voor de volledige
instructies en privacy regels.

Spawn agents met `model: "opus"`, elk gericht op één bron of invalshoek.
Elke agent gaat DIEP: hele threads lezen, links volgen, discussies
analyseren. Niet titels scrapen, maar argumenten begrijpen.

**Verplichte agents:**

| Agent | Opdracht |
|-------|----------|
| Friction | Sessie-analyse (Spoor A) |
| Skills ecosystem | awesome-agent-skills, agentskills.io, anthropics/skills |
| Community | Reddit, HN, DEV Community discussies |
| Blogs | Bekende auteurs (Hudson, Sundell, Majid, AvdLee, Fatbobman) |
| Claude Code updates | Changelog, nieuwe features, breaking changes |
| Concurrenten | Cursor, Windsurf, Copilot workflow vergelijking |

Extra thema-agents wanneer een focus actief is (zie explore.md).

#### Fase 2: Tussensynthese (synchroon, na ronde 1)

Lees alle agent-rapporten. Identificeer:
1. Meest interessante leads voor verdieping
2. Kruisbestuivingskansen (friction + extern)
3. Tegenstrijdigheden die opgelost moeten worden
4. Concrete vervolgvragen voor ronde 2

#### Fase 3: Gerichte diepte-agents (3-5 agents, ronde 2)

Elke agent krijgt een specifieke vervolgvraag uit de tussensynthese
plus relevante bevindingen uit ronde 1.

#### Fase 4: Contrarian verificatie (2-3 agents, ronde 3)

Het tegengewicht tegen confirmation bias:
- **Contrarian**: zoek bewijs dat conclusies niet kloppen
- **Verificatie**: zijn bronnen onafhankelijk of echo chamber?
- **Toepasbaarheid**: past dit bij onze constraints en filosofie?

#### Fase 5: Eindsynthese

Verwerk alle drie rondes tot definitief narratief. Per conclusie:
- **Robuust**: 3+ onafhankelijke bronnen, contrarian weerlegde niet
- **Waarschijnlijk**: 2+ bronnen, contrarian nuanceerde
- **Fragiel**: 1 bron, relevante tegenargumenten

Schrijf synthese naar state.md Knowledge Base.
Update Sources Crawled datums.

### 3. PLAN

Vertaal elke concrete bevinding naar een atomair plan-bestand.

**Per bevinding die overleeft:**
1. Check blocklist: staat het erop? → skip
2. Check bestaande plannen: bestaat er al een? → update of skip
3. Schrijf plan-bestand naar `~/.claude/recursion/plans/`

#### Bestandsnaam

`YYYY-MM-DD-korte-beschrijving.md`

Voorbeeld: `2026-03-25-hook-test-coverage-check.md`

#### Plan template

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

#### Kwaliteitseisen

Elk plan moet voldoen aan:

1. **Atomair**: implementeerbaar in één auto-loop sessie
2. **Self-contained**: auto-loop context bevat alles om te starten
3. **Overtuigend**: waarom-sectie laat geen twijfel
4. **Verifieerbaar**: concrete check of het werkt
5. **Afgebakend**: scope-begrenzing voorkomt creep

Te grote verbeteringen: splits in meerdere plannen met volgorde.

### 4. NOTIFY

Meld in de console welke plannen geschreven zijn:

```
Recursion klaar: N plannen geschreven.

[titels]

Plans: ~/.claude/recursion/plans/
Run: /auto-loop ~/.claude/recursion/plans/<bestand>
```

## Veiligheid

- Alle analyse van externe content MOET door Opus model agents
- Geen projectnamen, bedrijfsnamen, of persoonlijke namen in zoekopdrachten
- Geen content uploaden naar externe diensten
- Recursion wijzigt GEEN code, skills, hooks, of settings. Alleen plan-bestanden.
- Blocklist items worden nooit opnieuw voorgesteld

## Na de recursion (user-actie)

| User beslissing | Actie |
|-----------------|-------|
| Akkoord | `/auto-loop ~/.claude/recursion/plans/<bestand>` |
| Afwijzen | `/recursion reject <bestand>` (blocklist) |
| Parkeren | Niets doen, plan blijft `proposed`, volgende run kan het herontdekken |
