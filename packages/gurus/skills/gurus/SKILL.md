---
name: gurus
user-invocable: true
description: Orchestrator die tussen de guru-panels kiest. `gurus:software` voor code review door acht engineering-personas. `gurus:council` voor abstracte beslissingen door vijf adversariële lenzen plus chairman-synthese. Gebruik deze skill wanneer je /gurus hebt getypt zonder suffix en nog niet weet welk panel bij de vraag past.
allowed-tools:
  - Skill
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git status *)
  - Bash(git branch *)
effort: high
---

> **Preflight.** De sub-skills dispatchen via `gurus:sonnet-max`. Die agent bestaat vanaf plugin-versie 1.0.8. Wanneer de dispatch faalt met "unknown subagent_type: gurus:sonnet-max", draai `claude plugins update gurus@leclause` en probeer opnieuw.

# Gurus Orchestrator

Twee panels leven onder deze plugin:

- **`gurus:software`** doet opinionated code review met acht engineering-personas (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). Consensus over 6+/8 levert een actieplan.
- **`gurus:council`** doet kritiek op een beslissing of idee met vijf adversariële lenzen (pre-mortem, first-principles, opportunity-finder, stranger, action), anonieme peer review, chairman-synthese.

Deze orchestrator kiest welk panel past bij de vraag.

## Routing

### Impliciet signaal uit context

Lees eerst de context voordat je de user iets vraagt. Naast de conversatie mag je `git status`, `git log`, en `git diff` aanroepen om recente code-activiteit te checken; de frontmatter staat dat toe.

- **Software** is het juiste panel wanneer:
  - De conversatie een diff, code change, of codebase review bespreekt
  - De user een bestand of directory noemt om te reviewen
  - Er recent commits zijn gezet en de vraag voelt als "is dit goed?"
  - De user woorden gebruikt als "review", "refactor", "smell", "structure"
  - De user een technische correctheidsvraag stelt ("doet deze regex X?", "klopt deze query?"); dit is geen beslissing maar een code-vraag en valt onder software
  - De user een code-snippet plakt. Pass dat snippet als expliciete scope via `args`, zodat de software-skill niet per ongeluk de hele codebase scant

- **Council** is het juiste panel wanneer:
  - De vraag een afweging of beslissing is ("moet ik X of Y?"), geen vraag over code-correctheid
  - Het onderwerp strategisch, product-gericht, of interpersoonlijk is
  - De user twijfelt of Claude eerder alleen meeging ("was ik te hard voor je?" is een signaal)
  - De vraag bevat geen concrete technische correctheidsvraag

**Tiebreaker wanneer beide signalen vuren.** Een "should I use a service object here?" mengt een beslissingsvorm ("should I") met code-context. In dat geval: default naar **software**, want de code is de grond van waarheid; noem in de proposal-regel dat council ook past en geef de override expliciet.

Voorbeeld tiebreaker-proposal:

> Je vraagt of je een service object moet gebruiken, en je hebt code in context. Twee panels passen. Ik routeer naar **software** (code als grond van waarheid). Typ `council` om in plaats daarvan een design-beslissings-review te krijgen.

### Default en override

Bepaal een default op basis van de signalen en presenteer die aan de user. Voorbeeld:

> Ik zie een recente diff op `packages/foo/`. Ik routeer naar **`gurus:software`**. Typ `council` om naar het adversariële panel om te schakelen.

Of:

> Je vraag leest als een strategische keuze zonder code-context. Ik routeer naar **`gurus:council`**. Typ `software` om code review te krijgen.

Bij direct expliciet intent (user zei "council" of "software" in hun bericht) skip je deze check en dispatcht meteen.

### Geen signaal

Wanneer context leeg is of beide panels even plausibel zijn, stel één korte vraag:

> Twee panels beschikbaar: `software` voor code review, `council` voor een beslissing of idee. Welke past?

Stel deze vraag **één keer**. Het antwoord van de user is bindend; niet opnieuw bevestigen.

## Dispatch

Na routing: roep het gekozen panel aan via de Skill tool. Voor software gebruik je `skill="gurus:software"`; voor council `skill="gurus:council"`. De `args` bevatten de concrete vraag of scope die de user aanlevert.

**Wanneer de user `/gurus:gurus` typte zonder begeleidende tekst**, is er geen letterlijke vraag om door te geven. Synthetiseer dan een één-zin samenvatting van het lopende onderwerp uit de conversatie (eventueel verrijkt met de output van `git status` of `git log -1`) en pass die als `args`. Houd de samenvatting neutraal; geen framing die het panel naar een bepaald oordeel stuurt.

**Wanneer de user een code-snippet plakte**, pass dat snippet als expliciete scope in `args` zodat `gurus:software` niet de volledige codebase scant maar enkel het snippet (en eventueel het omringende bestand dat de user erbij noemde).

De sub-skills nemen het over. Deze orchestrator doet geen review zelf.

## Regels

- **Routing is snel.** Maximaal één vraag aan de user voordat je dispatcht. Elke tweede vraag is een faalmodus.
- **Expliciete intent wint.** Wanneer de user in de invocatie al `software` of `council` heeft genoemd, skip de routing-stap en dispatch direct.
- **Niet zelf reviewen.** Deze skill presenteert alleen de keuze en delegeert. Inhoudelijke review gebeurt in de sub-skill.
- **Blijf neutraal tussen panels.** Presenteer beide als legitiem; de context bepaalt welke past, niet welke panel "beter" is.
