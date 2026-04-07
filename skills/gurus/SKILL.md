---
name: gurus
description: Use when code needs opinionated review from multiple expert perspectives. Triggers on /gurus, expert review panel, guru review, or when seeking consensus across engineering philosophies.
allowed-tools:
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git status *)
  - Bash(git branch *)
  - Bash(wc *)
---

# Guru Panel Review

Acht opinionated engineers reviewen je code en zoeken consensus over wat beter moet. Wanneer 6+/8 het eens zijn, wordt een actieplan gemaakt. De waarde zit in de spanning tussen hun perspectieven: consensus ondanks fundamenteel verschillende stijlen is een sterk signaal.

## Scope bepalen

De default scope is altijd de **volledige codebase** (alle bronbestanden
in de relevante directory). Agents lezen alle bestanden, niet alleen een
diff. Een diff biased de review naar gewijzigde code en mist problemen
in ongewijzigde bestanden.

Wanneer de user expliciet een beperktere scope aangeeft (een bestand,
directory, of commit range), gebruik die. Maar zonder expliciete scope:
geef agents een bestandslijst en laat ze alles lezen.

## Het panel

| # | Guru | Zwaartepunt |
|---|------|-------------|
| 1 | **Thoughtbot** (quorum) | Testbaarheid, API design, developer experience, conventie-adherentie. Playbook-denken: iteratief, test-first, pragmatisch |
| 2 | **Kent Beck** | Vier regels van simpel design, duplicatie elimineren, intentie onthullen. XP Explained, TDD By Example. "What's the simplest thing that could possibly work?" |
| 3 | **Martin Fowler** | Code smells, refactoring kansen, domeinmodellering, ubiquitous language. Refactoring, PoEAA, bliki. "I smell Feature Envy here." |
| 4 | **Uncle Bob** | Clean Code, SOLID, function/class grootte, naamgeving, architectuur boundaries, dependency direction. "This function does more than one thing." |
| 5 | **DHH** | Pragmatisme, conventie boven configuratie, tegen over-abstractie en onnodige indirectie. Rails doctrine, Majestic Monolith. "You don't need a service object here. Ship it." |
| 6 | **Sandi Metz** | Objectverantwoordelijkheid, composition over inheritance, dependency injection, Flocking Rules. POODR, 99 Bottles. "What does this class know that it shouldn't?" |
| 7 | **Tobi Lutke** | Schaalbaarheid, pragmatische tradeoffs, system thinking, shipping culture. Shopify-schaal engineering. "Will this work at 10x scale?" |
| 8 | **Rich Hickey** | Data-oriented design, immutability, simplicity als afwezigheid van complexiteit. Simple Made Easy, Clojure's filosofie. "Are we simplifying, or are we just making it easy?" Bevraagt OOP-aannames die de rest van het panel deelt. |

**Kenmerkende spanningen**: DHH vs Uncle Bob op abstractieniveau. Beck's simplicity vs Fowler's patterns. Metz's kleine objecten vs DHH's pragmatisme. Lutke's schaaldenken vs Beck's YAGNI. Hickey vs het hele panel op OOP als default lens: zijn "just use data" staat haaks op Metz' objecten, Uncle Bob's abstracties, en Fowler's patterns. Wanneer 5+ het eens zijn ondanks deze spanningen, is dat een sterk signaal.

## Workflow

### Stap 1: Materiaal verzamelen

Verzamel de bestandslijst voor de scope (default: alle bronbestanden).
Geef agents de bestandslijst en laat ze zelf lezen. Geef GEEN diff mee
als scope, tenzij de user expliciet om een diff-review vraagt.

### Stap 2: Acht agents parallel dispatchen

Eén message met 8 parallelle `Agent` calls (`subagent_type: "general-purpose"`). De agents reviewen alleen, ze wijzigen NIETS.

**Prompt template per agent** (vul in per guru):

```
Je bent [NAAM]. Je reviewt code vanuit het zwaartepunt van je eigen filosofie, gestoeld op je volledige oeuvre.

[PERSONA: 2-3 zinnen die het zwaartepunt beschrijven, uit de tabel hierboven. Gebruik de genoemde werken en citaten als anker.]

Je zit in een review panel met 7 andere experts: [OVERIGE NAMEN]. Jullie hebben fundamenteel verschillende stijlen maar zijn allemaal op de piek van jullie kunnen. Wees opinionated en direct. Geen diplomatie, geen "het hangt ervan af". Zeg wat je vindt.

## Te reviewen

[BESTANDSLIJST van alle bronbestanden in de scope]

Lees ALLE bestanden in de lijst volledig. Review de hele codebase, niet
alleen wat recent is gewijzigd. Lees ook de CLAUDE.md in de project root
(als die bestaat) voor projectconventies.

## Output (volg dit formaat exact)

### Wat deugt
- [max 3 punten, kort en specifiek]

### Wat beter moet
Genummerde lijst. Per punt:

1. **[Korte titel]**
   Locatie: `bestand:regel` of `bestand:functienaam`
   Probleem: [wat is er mis, vanuit jouw specifieke perspectief]
   Voorstel: [concreet, implementeerbaar verbetervoorstel]

Wees specifiek. Verwijs naar concrete bestanden en regels. Geen algemeenheden. Maximaal 7 punten, focus op wat er het meest toe doet.
```

### Stap 3: Synthese

Na ontvangst van alle 8 reviews:

1. **Groepeer** semantisch vergelijkbare verbeterpunten. "Method too long" (Beck) en "violates SRP" (Uncle Bob) over dezelfde method zijn hetzelfde punt
2. **Tel** hoeveel gurus elk gegroepeerd punt hebben benoemd
3. **Sorteer** op consensus (hoogste eerst)
4. **Splits** op de 6/8 drempel (6 of meer van de 8 panelleden)
5. **Singleton-punten bewaren.** Een punt dat slechts 1/8 consensus haalt is niet per definitie ongeldig. Presenteer alle punten met 1+ gurus in de discussiesectie. Een hardcoded string array, een polymorfisme-kandidaat, of een vergeten guard is reëel ongeacht hoeveel gurus het benoemden. De user beslist wat er mee gebeurt, niet het consensus-niveau

### Stap 4: Presenteer

Gebruik dit formaat:

```
## Guru Panel Review

### Gereviewd
[Branch of scope] — [X bestanden, Y regels diff]

---

### Consensus (6+/8): Actieplan

1. **[Titel]** (X/8: [namen van gurus die het eens zijn])
   [Synthese van het probleem vanuit de verschillende perspectieven]
   **Locatie:** `bestand:regel`
   **Voorstel:** [concrete verbetering, samengevoegd uit de voorstellen]

---

### Discussiepunten (<6/8)

2. **[Titel]** (X/8: [namen])
   [Beschrijving]
   **Voorstel:** [concrete verbetering]
   *Dissent: [namen] vinden [tegenargument]*

---

### Wat deugt
[Samenvatting van highlights die meerdere gurus benoemden]

---

Typ **"doe het"** om de consensuspunten toe te passen, of **/auto-loop** voor autonome uitvoering.
```

### Stap 5: Uitvoering

Bij **"doe het"**:
- Voer consensuspunten sequentieel uit
- Eén commit per logisch onafhankelijk punt
- Normale commit-regels (intent validatie)

Bij **/auto-loop**:
- Start een auto-loop met de consensuspunten als taken
- Autonome uitvoering
- De auto-loop Context sectie moet aangeven dat de loop zichzelf
  stopt (CronDelete + `/recap`) wanneer alle guru-punten zijn
  afgewerkt en gecommit. Guru-werk is eindig: er is geen externe
  input om op te wachten na het committen.

Discussiepunten worden alleen uitgevoerd als de user ze expliciet goedkeurt.


