---
name: recursion
user-invocable: true
description: >
  Use when scheduling or managing the nightly workflow-improvement loop.
  Triggers on /recursion, "schedule on/off", status check, focus set,
  or plan reject. Manages cron, state, focus, and the blocklist.
  Dispatches research runs to the research sub-skill of the same plugin.
  Does not perform research itself.
argument-hint: "[now | on | off | status | focus <thema> | reject <file>]"
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
  - CronCreate
  - CronDelete
  - RemoteTrigger
  - Skill
---

# Recursion

Orchestrator voor de nightly improvement loop. Beheert cron, state,
focus, blocklist en de reject-flow. Draait zelf geen research. Voor de
daadwerkelijke research workflow en safety regels: zie de `research`
sub-skill (`recursion:research`).

## State eigenaarschap

Orchestrator is de enige schrijver van `schedule_id`, `focus`, en
`blocklist.md` appends. De status-flip van een plan naar `rejected` is
ook orchestrator-werk. Alle andere velden in `state.md` en `plans/*.md`
zijn eigendom van de `research` sub-skill. Volledige ownership-tabel
staat in `skills/research/SKILL.md § State contract`.

## Subcommando's

| Argument | Actie |
|----------|-------|
| _(geen)_ | Eenmalige run vannacht om 1:03 (session-only) |
| `now` | Direct starten in huidige sessie |
| `on` | Permanente nachtelijke schedule |
| `off` | Schedule stoppen |
| `status` | Toon state, actieve plannen, schedule |
| `focus <thema>` | Thematisch filter instellen |
| `focus off` | Terug naar brede verkenning |
| `reject <bestand>` | Markeer plan als rejected, voeg toe aan blocklist |

## Delegatie naar research

Eén contract, twee paden (in-session versus achtergrond cron). Gebruik
exact een van deze twee.

**In-session (synchrone Skill tool call):**

```
Skill(skill: "recursion:research")
```

De Skill tool wacht tot de research run klaar is en retourneert de
NOTIFY-output. Dit is het pad voor `/recursion now`.

**Cron / RemoteTrigger (verse sessie):**

Verse sessies kunnen een sub-skill niet direct als slash-command
aanroepen (research is niet user-invocable). Cron prompt daarom:

```
prompt: "/recursion now"
```

De verse sessie laadt dan de orchestrator en die dispatcht via de Skill
tool naar research. Eén ingang, één codepad.

### `/recursion` (eenmalig vannacht)

1. Bereken cron voor vannacht 1:03: `3 1 <dag> <maand> *`
2. CronCreate met `recurring: false` en prompt `/recursion now`
3. Waarschuw: session-only, verdwijnt als sessie sluit

### `/recursion now`

1. Roep `Skill(skill: "recursion:research")` aan. Wacht synchroon op
   terugkeer.
2. Toon de NOTIFY-output die de research skill retourneert.
3. Geen aparte state-updates in de orchestrator; de research skill
   beheert zijn eigen state velden.

### `/recursion on` / `off`

Gebruik RemoteTrigger via de `/schedule` skill. Cron: `3 1 * * *`.
Prompt in de trigger: `/recursion now`.
Sla trigger ID op in state.md als `schedule_id`.

`off` stopt de trigger via `schedule_id` en wist het veld uit state.md.

### `/recursion status`

Toon: `last_run` en `total_runs` (gelezen uit state.md),
actieve focus thema, schedule actief (`schedule_id` aanwezig?),
en een overzicht van plannen per `status` veld
(`proposed`/`rejected`/`implemented`).

Status is read-only voor de orchestrator: leest state.md en plan
frontmatter, schrijft niets.

### `/recursion reject <bestand>`

1. Lees het plan in `~/.claude/recursion/plans/<bestand>`
2. Wijzig alleen het `status` veld van `proposed` naar `rejected` in de
   frontmatter. Raak de body niet aan.
3. Voeg toe aan `~/.claude/recursion/blocklist.md` met datum en reden.
4. Meld wat afgewezen en geblocklist is.

### `/recursion focus <thema>` / `focus off`

Schrijf `focus` veld naar state.md. `focus off` wist het veld. Volgende
research-run leest dit veld in PREPARE en stuurt thema-agents
dienovereenkomstig aan.

## Schrijfrechten

Orchestrator raakt alleen:

- `~/.claude/recursion/state.md` velden `schedule_id` en `focus`
- `~/.claude/recursion/blocklist.md` (append)
- `~/.claude/recursion/plans/*.md` frontmatter `status` veld (alleen bij
  reject)

Alle andere writes in `~/.claude/recursion/` zijn onbevoegd. Nooit schrijven
buiten `~/.claude/recursion/`.

## Na de recursion (user-actie)

| User beslissing | Actie |
|-----------------|-------|
| Akkoord | `/auto-loop ~/.claude/recursion/plans/<bestand>` |
| Afwijzen | `/recursion reject <bestand>` (blocklist) |
| Parkeren | Niets doen, plan blijft `proposed`, volgende run kan het herontdekken |
