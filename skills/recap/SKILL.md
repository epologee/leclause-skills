---
name: recap
description: Use when the user needs a status overview of the current session. Triggers on /recap, or when returning to a session after idle time, compaction, or repetitive background output.
---

# Recap

Geef een gestructureerd overzicht van waar we op dit moment staan.

## Bronnen verzamelen

**Gesprekscontext is altijd de primaire bron.** Wat er in het huidige gesprek is besproken en besloten bepaalt het hoofdverhaal. Auto-loop bestanden en git status zijn aanvullend. Laat je niet afleiden door bestanden op disk die niets met het huidige werk te maken hebben. Een auto-loop bestand in OBSERVE met hoge watch_checks is achtergrondruis, niet het hoofdverhaal.

Voer deze tool calls parallel uit:

1. **Gesprekscontext** - wat er in het huidige gesprek is besproken en besloten
2. **Git status** - `git status` en `git diff --stat` voor uncommitted changes, `git log --oneline -10` voor recente activiteit
3. **Auto-loops** - `ls auto-loops/` in de project root. Alleen relevant als ze actief zijn (recente log entries, niet-OBSERVE phase, of lage watch_checks)
4. **Cron jobs** - CronList voor draaiende achtergrondtaken
5. **Taken** - TaskList voor lopende achtergrondprocessen

Niet elke bron levert iets op. Dat is prima. Presenteer wat er is.

## Output formaat

Drie secties, kort en functioneel:

**Bezig met**
Het doel van het huidige werk in 1-2 zinnen. Niet de technische details, maar het verhaal: waarom zitten we hier, wat proberen we te bereiken.

**Status**
Waar staan we nu? Fase (als auto-loop actief), wat is er gedaan, wat draait op de achtergrond. Noem branch en uncommitted changes als die er zijn.

**Te doen**
Wat staat er nog open? Wat wacht op input, wat draait autonoom, wat moet de user beslissen. Eindig met een concreet vervolgvoorstel.

## Richtlijnen

- **Kort en concreet.** Geen bestandslijsten, geen technische opsommingen. Functionele beschrijving.
- **Eerlijk over onzekerheid.** Als context verloren is door compaction, zeg dat. Niet gokken.
- **Altijd actionable.** De user moet na het lezen weten wat de volgende concrete stap is.
- **Geen samenvatting van de samenvatting.** Niet herhalen wat de user net zelf heeft getypt of gezien. Focus op wat niet zichtbaar is vanuit de herhalende output.
