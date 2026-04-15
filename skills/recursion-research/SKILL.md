---
name: recursion-research
user-invocable: true
description: >
  Use when executing the deep research workflow that produces atomic
  improvement plans for the Claude Code setup. Triggers on
  /recursion-research, "wat kunnen we verbeteren", "workflow
  improvements", "research run", explicit delegation from the recursion
  orchestrator, or scheduled nightly runs. Spawns parallel Opus agents
  for friction analysis and external discovery, synthesizes findings
  across three rounds, and writes self-contained plan files. Research
  machine only, never executes the plans it produces.
argument-hint: "(no arguments, input comes from ~/.claude/recursion/state.md)"
allowed-tools:
  - Bash(date *)
  - Bash(stat *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Bash(rm *)
  - Bash(git -C ~/.claude *)
  - Edit(~/.claude/recursion/**)
  - Write(~/.claude/recursion/**)
  - Read(~/.claude/**)
  - Glob(~/.claude/**)
  - Grep(~/.claude/**)
  - WebSearch
  - WebFetch(*)
  - Agent
---

# Recursion Research

Research machine achter de recursion improvement loop. Produceert
kant-en-klare plannen door drie rondes deep research (verkenning,
diepte, contrarian). Schrijft plannen in `~/.claude/recursion/plans/`.
Voert de plannen niet uit.

## State contract

Beide recursion skills (`recursion` orchestrator en `recursion-research`)
delen `~/.claude/recursion/`. Om race conditions te voorkomen heeft elk
state-veld één schrijver:

| Bestand / veld | Eigenaar | Andere skill mag |
|----------------|----------|------------------|
| `state.md` `schedule_id` | `recursion` | lezen |
| `state.md` `focus` | `recursion` | lezen |
| `state.md` `last_run` | `recursion-research` | lezen |
| `state.md` `total_runs` | `recursion-research` | lezen |
| `state.md` Knowledge Base | `recursion-research` | lezen |
| `state.md` Sources Crawled | `recursion-research` | lezen |
| `blocklist.md` | `recursion` (append bij reject) | lezen |
| `plans/*.md` nieuwe bestanden | `recursion-research` | lezen |
| `plans/*.md` `status` veld | `recursion` (flip naar rejected) | lezen |

De plan-body (alle velden behalve `status`) is immutable na creatie.

## Input

Alle input komt uit state. Geen argumenten. Bij start leest de skill:

1. `last_run` timestamp uit `state.md` (bepaalt friction-analyse scope)
2. `focus` thema uit `state.md` (bepaalt welke thema-agents spawnen)
3. `blocklist.md` (bepaalt welke bevindingen geskipt worden)
4. bestaande plan-slugs in `plans/` (voorkomt duplicaten)

## Output

- Nieuwe plan-bestanden in `~/.claude/recursion/plans/` volgens
  `${CLAUDE_SKILL_DIR}/prompts/plan-template.md`
- Bijgewerkte `last_run`, `total_runs` velden in `state.md`
- Bijgewerkte Knowledge Base en Sources Crawled secties in `state.md`
- Console notificatie met aantal en titels van geschreven plannen

## Workflow

Vier top-level stappen, RESEARCH bevat drie onderzoeksrondes gescheiden
door syntheses.

```
PREPARE → RESEARCH (ronde 1 → tussensynthese → ronde 2 → ronde 3 → eindsynthese) → PLAN → NOTIFY → STOP
```

### 1. PREPARE

1. Haal datum op: `date +%Y-%m-%d`
2. Lees `state.md`. Noteer `last_run`, `total_runs`, en `focus`.
3. Lees `blocklist.md` volledig in context (wordt als filter doorgegeven
   aan Spoor A en B).
4. Scan bestaande plannen: `ls ~/.claude/recursion/plans/*.md` om
   slugs te verzamelen.
5. Update `last_run` pas na een succesvolle PLAN fase, niet hier. Een
   gefaalde run mag niet als geslaagd geregistreerd staan.

### 2. RESEARCH

Dit is het hart. Grondig, radicaal, geen concessies. Spawn parallelle
Opus agents per onderzoeksrichting.

#### Ronde 1: Parallelle verkenning (Spoor A + Spoor B)

**Spoor A: Friction Analysis** (één agent, parallel met Spoor B)

Spawn een Opus agent met de prompt uit
`${CLAUDE_SKILL_DIR}/prompts/friction-analysis.md`.
Analyseert sessie-JSONLs sinds `last_run` op friction patronen:
correcties, overclaimed confidence, compliance reflex, premature action,
doel-abandonment, downgrade-spiralen, herhaalde instructies,
self-improvement audit.

**Spoor B: Externe Research** (5-10 parallelle agents)

Lees `${CLAUDE_SKILL_DIR}/prompts/explore.md` voor de volledige
instructies en privacy regels.

Spawn agents met `model: "opus"`, elk gericht op één bron of invalshoek.
Elke agent gaat DIEP: hele threads lezen, links volgen, discussies
analyseren. Niet titels scrapen, maar argumenten begrijpen.

Verplichte agents:

| Agent | Opdracht |
|-------|----------|
| Skills ecosystem | awesome-agent-skills, agentskills.io, anthropics/skills |
| Community | Reddit, HN, DEV Community discussies |
| Blogs | Bekende auteurs (Hudson, Sundell, Majid, AvdLee, Fatbobman) |
| Claude Code updates | Changelog, nieuwe features, breaking changes |
| Concurrenten | Cursor, Windsurf, Copilot workflow vergelijking |

Wanneer `focus` gezet is in state.md: spawn bovenop de verplichte agents
ook de thema-specifieke agents uit `explore.md § Thema-Specifieke
Bronnen`. Wanneer `focus` leeg is: brede verkenning zonder thema-filter.

#### Tussensynthese (synchroon, na ronde 1)

Lees alle agent-rapporten. Identificeer:

1. Meest interessante leads voor verdieping
2. Kruisbestuivingskansen (friction + extern)
3. Tegenstrijdigheden die opgelost moeten worden
4. Concrete vervolgvragen voor ronde 2

#### Ronde 2: Gerichte diepte-agents (3-5 agents)

Elke agent krijgt een specifieke vervolgvraag uit de tussensynthese
plus relevante bevindingen uit ronde 1.

#### Ronde 3: Contrarian verificatie (2-3 agents)

Het tegengewicht tegen confirmation bias:

- **Contrarian**: zoek bewijs dat conclusies niet kloppen
- **Verificatie**: zijn bronnen onafhankelijk of echo chamber?
- **Toepasbaarheid**: past dit bij onze constraints en filosofie?

#### Eindsynthese

Verwerk alle drie rondes tot definitief narratief. Per conclusie:

- **Robuust**: 3+ onafhankelijke bronnen, contrarian weerlegde niet
- **Waarschijnlijk**: 2+ bronnen, contrarian nuanceerde
- **Fragiel**: 1 bron, relevante tegenargumenten

Schrijf synthese naar state.md Knowledge Base.
Update Sources Crawled datums.

### 3. PLAN

Vertaal elke concrete bevinding naar een atomair plan-bestand volgens
`${CLAUDE_SKILL_DIR}/prompts/plan-template.md` (single source of truth
voor schema en kwaliteitseisen).

Per bevinding die de eindsynthese overleeft:

1. Check blocklist (reeds ingelezen in PREPARE). Staat het erop? Skip.
2. Check bestaande plan-slugs. Bestaat er al een met dezelfde strekking?
   Update of skip.
3. Schrijf nieuw plan-bestand naar `~/.claude/recursion/plans/` met
   `status: proposed`.

Pas nu (na de laatste write) is de run echt voltooid. Werk
`last_run` en `total_runs` bij in state.md.

### 4. NOTIFY

Meld in de console welke plannen geschreven zijn:

```
Recursion klaar: N plannen geschreven.

[titels]

Plans: ~/.claude/recursion/plans/
Run: /auto-loop ~/.claude/recursion/plans/<bestand>
```

## Veiligheid

Single source of truth voor privacy en safety regels. Ook van toepassing
op de `recursion` orchestrator wanneer die via de Skill tool delegeert.

- Alle analyse van externe content MOET door Opus model agents.
- Geen projectnamen, bedrijfsnamen of persoonlijke namen in zoekopdrachten
  (zie `prompts/explore.md § Privacy Regels`).
- Geen content uploaden naar externe diensten.
- Recursion-research wijzigt GEEN code, skills, hooks of settings buiten
  `~/.claude/recursion/`. Alleen plan-bestanden en state velden uit het
  ownership tabel hierboven.
- Blocklist items worden nooit opnieuw voorgesteld.
