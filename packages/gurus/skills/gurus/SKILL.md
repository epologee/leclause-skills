---
name: gurus
user-invocable: true
description: Orchestrator die tussen de guru-panels kiest. `gurus:software` voor code review door acht engineering-personas. `gurus:council` voor abstracte beslissingen door vijf adversariële lenzen plus chairman-synthese. Gebruik deze skill wanneer je /gurus hebt getypt zonder suffix en nog niet weet welk panel bij de vraag past.
allowed-tools:
  - Skill
---

# Gurus Orchestrator

Twee panels leven onder deze plugin:

- **`gurus:software`** doet opinionated code review met acht engineering-personas (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). Consensus over 6+/8 levert een actieplan.
- **`gurus:council`** doet kritiek op een beslissing of idee met vijf adversariële lenzen (pre-mortem, first-principles, opportunity-finder, stranger, action), anonieme peer review, chairman-synthese.

Deze orchestrator kiest welk panel past bij de vraag.

## Routing

### Impliciet signaal uit context

Lees eerst de context voordat je de user iets vraagt:

- **Software** is het juiste panel wanneer:
  - De conversatie een diff, code change, of codebase review bespreekt
  - De user een bestand of directory noemt om te reviewen
  - Er recent commits zijn gezet en de vraag voelt als "is dit goed?"
  - De user woorden gebruikt als "review", "refactor", "smell", "structure"
  - De user een technische correctheidsvraag stelt ("doet deze regex X?", "klopt deze query?"); dit is geen beslissing maar een code-vraag en valt onder software

- **Council** is het juiste panel wanneer:
  - De vraag een afweging of beslissing is ("moet ik X of Y?"), geen vraag over code-correctheid
  - Het onderwerp strategisch, product-gericht, of interpersoonlijk is
  - De user twijfelt of Claude eerder alleen meeging ("was ik te hard voor je?" is een signaal)
  - De vraag bevat geen concrete technische correctheidsvraag

**Tiebreaker wanneer beide signalen vuren.** Een "should I use a service object here?" mengt een beslissingsvorm ("should I") met code-context. In dat geval: default naar **software**, want de code is de grond van waarheid; noem in de proposal-regel dat council ook past en geef de override expliciet.

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

Na routing: roep het gekozen panel aan via de Skill tool.

```
Skill(skill="gurus:software", args="<de oorspronkelijke vraag van de user>")
```

of

```
Skill(skill="gurus:council", args="<de oorspronkelijke vraag van de user>")
```

De sub-skills nemen het over. Deze orchestrator doet geen review zelf.

## Regels

- **Routing is snel.** Maximaal één vraag aan de user voordat je dispatcht. Elke tweede vraag is een faalmodus.
- **Expliciete intent wint.** Wanneer de user in de invocatie al `software` of `council` heeft genoemd, skip de routing-stap en dispatch direct.
- **Niet zelf reviewen.** Deze skill presenteert alleen de keuze en delegeert. Inhoudelijke review gebeurt in de sub-skill.
- **Blijf neutraal tussen panels.** Presenteer beide als legitiem; de context bepaalt welke past, niet welke panel "beter" is.
