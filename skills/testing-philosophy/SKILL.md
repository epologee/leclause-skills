---
name: testing-philosophy
description: Use when writing tests, debugging test failures, reviewing test strategy, or making decisions about what/how to test. Covers TDD workflow, Cucumber/Gherkin conventions, flaky tests, and test suite health.
---

# Testing Philosophy

Principes en conventies voor testen. De kernregels (TDD verplicht, tests aanpassen verboden, falende tests blokkeren alles) staan in de CLAUDE.md. Deze skill bevat de uitwerking.

## Red-Green-Refactor is verplicht

TDD is hoe we intentie verankeren in code. De falende test is het moment waarop we vastleggen wat we willen, voordat we vastleggen hoe we het bouwen. Het is geen technische formaliteit, het is het mechanisme waarmee respect voor intentie concreet wordt.

**NOOIT implementatie schrijven voordat je een falende test hebt gezien.**

Dit is niet optioneel. Dit is niet "waar mogelijk". Dit is ALTIJD, voor elke feature en elke bugfix.

**Workflow:**
1. **Red**: Schrijf test die huidige gedrag vastlegt -> moet FALEN
2. **Green**: Implementeer minimale code om test te laten slagen
3. **Refactor**: Cleanup met groene tests als vangnet

**Bij bugfixes:**
- Schrijf test die de bug reproduceert (faalt)
- Fix de bug (test wordt groen)
- Verifieer door fix te reverten -> test MOET opnieuw falen

**Dit geldt altijd.** Zelfs voor "triviale" changes. Zelfs voor "urgent" fixes.

**Een uitzondering: puur cosmetische wijzigingen.** CSS classes, kleuren, spacing, font sizes en andere visuele styling hoeven geen TDD dekking. Tests die specifieke CSS classes of design tokens asserteren maken het test-harnas te rigide voor voortschrijdend design-inzicht. Test het gedrag, niet de presentatie.

**RED -> GREEN -> REFACTOR is een doorlopende flow.** Pauzeer niet tussen fases om toestemming te vragen. Als de gebruiker een opdracht heeft gegeven ("fix dit", "pas dat aan"), doorloop dan de volledige TDD cyclus zonder te stoppen. Het enige pauzemoment is NA de cyclus, wanneer het resultaat klaar is voor review.

## UI/UX bugs krijgen Cucumber scenarios

Wanneer een bug betrekking heeft op gebruikersinteractie (knoppen, formulieren, navigatie, confirm dialogs, statustransities in de browser): schrijf een Cucumber scenario, geen unit test. Cucumber beschrijft het gedrag vanuit gebruikersperspectief en test de volledige stack inclusief JavaScript.

Unit tests (RSpec requests, model specs) zijn voor server-side logica. Cucumber scenarios zijn voor alles wat een gebruiker ziet en doet.

## Gherkin scenarios zijn domein-documentatie

Feature files beschrijven gedrag in domein-taal, niet UI-interacties. Ze zijn documentatie die toevallig executable is.

**Declaratief (goed):** `When I create a todo "Buy groceries"` -> beschrijft intent, overleeft UI redesigns.
**Imperatief (verboden):** `When I fill in the "title" field with "Buy groceries" And I click the "Add" button` -> breekt bij elke UI wijziging, leest als een testscript in plaats van documentatie.

De UI-mechaniek (welk veld, welke knop, hover voor verborgen elementen) leeft in step definitions, niet in feature files. Als de UI verandert, veranderen alleen step definitions. De scenarios, en daarmee de gedragsdocumentatie, blijven stabiel.

**BRIEF principes:** Business language, Real data, Intention revealing, Essential, Focused, Brief (~5 regels per scenario).

## Test scaffolding is geen voortgang

Een scenario dat je uitschrijft maar tagt als `@wip` of op een andere manier excludet van de test suite, is geen test. Het is een wensenlijst in code-formaat. Step definitions die alleen `PendingException` throwen (of het equivalent in andere talen) zijn cruft bij geboorte.

De TDD-cyclus begint bij Red: een test die je nooit rood hebt zien draaien heeft de cyclus niet doorlopen. Schrijf een scenario, implementeer de steps volledig, zie het groen worden. Dan het volgende scenario. Nooit meerdere lege scenario's tegelijk aanmaken.

Feature files die alleen uit ongeimplementeerde scenarios bestaan, horen niet te bestaan. Als je nog niet aan die feature toekomt, schrijf er geen test voor. "De structuur alvast klaarzetten" is planning vermomd als code. "Steps aanmaken zodat Cucumber niet klaagt" is scaffolding vermomd als voortgang. "@wip taggen zodat CI groen blijft" is uitstel vermomd als pragmatisme.

## Red Flags - Je bent aan het rationaliseren

Als je jezelf betrapt op deze gedachten, STOP:
- "Dit is te simpel om te testen"
- "Ik test het straks wel"
- "Ik zet de structuur alvast klaar"
- "Ik tag het als @wip, dan maken we het later af"
- "Eerst even kijken of het werkt"
- "Laat me de implementatie checken"
- "De user heeft haast"
- "Het is maar een regel"

-> Je bent aan het rationaliseren. Schrijf eerst de test.

## Test setup richtlijnen

Minimaliseer test-level memoization/setup. Geef de voorkeur aan lokale variabelen binnen de test zelf.

## TDD als verificatie
TDD is een menselijk verificatie checkpoint:
1. **Red**: Mens kan verwacht gedrag reviewen in de falende test
2. **Green**: Mens kan verifieren dat implementatie overeenkomt met intent
3. **Refactor**: Mens kan het contract (tests) valideren zelfs wanneer AI de implementatie schrijft

## Main branch is altijd groen
Neem nooit aan dat een test zou kunnen falen op main. Als het op main staat, slaagt het. Bij het verifieren van test gedrag:
- Schrijf een test die het verwachte gedrag vastlegt
- Bij het testen van een fix, pas de fix lokaal toe, run de test, revert dan de fix om de test te zien falen
- Nooit main uitchecken om "te checken of deze test daar faalt". Dat is het verkeerde mentale model
- Bij het refereren naar main, gebruik altijd `origin/main` aangezien lokale main stale kan zijn

## Tests aanpassen is verboden
Een falende test betekent: fix de CODE, niet de test. Nooit een test verzwakken om hem groen te krijgen.

**Uitzondering:** Alleen wanneer requirements daadwerkelijk zijn veranderd, en dan alleen na expliciete bevestiging van de user.

## Demo is geen test
Handmatige verificatie (demo's, console output, "even proberen") is geen bewijs dat code werkt. Demo output varieert en is niet deterministisch.

**Verboden:** Een applicatie draaien om te verifieren dat code werkt.
**Verplicht:** Geautomatiseerde tests met voorspelbare input/output.

## Code lezen is geen test
Source code lezen om te deduceren of iets werkt is geen verificatie. Grep door implementatie vertelt je wat de code doet, niet of het gedrag klopt vanuit gebruikersperspectief. Wanneer de vraag is "werkt X?", is het antwoord een test die X uitoefent, niet een code review die concludeert dat het zou moeten werken.

**Verboden:** `grep`/`read` door handlers en queries om te concluderen dat een feature werkt.
**Verplicht:** Schrijf een test die het gedrag vanuit de gebruiker exerceert. De test is het bewijs.

## Flaky tests zijn een investering

**Definitie van flaky:** Non-deterministische tests die soms groen, soms rood zijn zonder code change.

**Flaky tests zijn NOOIT acceptabel:**
- Kosten alle teamgenoten tijd op alle projecten
- Eroderen vertrouwen in de test suite
- Maskeren echte regressies
- Erin investeren om te fixen is altijd de juiste lange termijn beslissing

**Gebruik "flaky" ALLEEN voor non-deterministische tests:**
- Flaky: Test faalt soms door race condition, timing issue, shared state
- Niet flaky: Test faalt altijd door missende mock/stub
- Niet flaky: Test faalt altijd door externe dependency (API, database)
- Niet flaky: Test faalt altijd door incomplete implementatie

**Wanneer je een flaky test tegenkomt:**
1. Stop met huidige werk
2. Verzamel context: test path, command om te runnen, error output, failure rate
3. Stel voor om dedicated onderzoek te starten met volledige context
4. Genereer `claude -p` command met:
   - Test file path en regel nummer
   - Exact commando om test te runnen
   - Error output van laatste failure
   - Geschatte failure rate (bijv. "faalt ~30% van de tijd")
   - Hypothese over oorzaak (race condition, timing, shared state, etc.)
5. NOOIT automatisch proberen te fixen tijdens ander werk
6. NOOIT "retry until green" of flakiness maskeren

## Falende tests blokkeren alles

Wanneer de test suite failures heeft, is het enige juiste antwoord: fixen. Niet deployen, niet committen, niet "dat zijn pre-existing failures". Falende tests zijn werk, net als warnings. Het maakt niet uit of ze van jouw wijziging komen of al bestonden.

**Verboden:** Deployen of committen voorstellen terwijl de suite failures heeft.
**Verboden:** Failures wegwuiven als "pre-existing" of "niet gerelateerd aan mijn wijziging".
**Verplicht:** Failures onderzoeken, fixen, en de suite groen krijgen voordat je verder gaat.

**Red Flags bij test failures:**
- "Lijkt niet gerelateerd aan mijn wijzigingen" -> Irrelevant. Het faalt. Fix het.
- "Laat me verifieren dat het pre-existing is" -> Het doel is fixen, niet schuld toewijzen.
- "Dit is een data-issue, geen [mijn ding]" -> Categoriseren is geen oplossen.
- "Even checken of het op main ook faalt" -> Zelfs als dat zo is, is het nu jouw probleem.
- git stash om te bewijzen dat het "niet van jou" is -> Verkeerde richting. Onderzoek de failure, niet de oorsprong.

**Bij CI-failures die onverwacht breken:** Wanneer je ontdekt dat je wijzigingen tests breken op plekken die je niet had verwacht (bijv. component specs die org context nodig hebben terwijl je routes wijzigde), is dat een signaal dat er meer onverwachte breakages kunnen zijn. Draai in die situatie de volledige suite voordat je de fix commit. Zeker niet amenden op een vorige commit voordat je weet dat het hele plaatje klopt.
