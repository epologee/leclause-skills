---
name: testing-philosophy
user-invocable: false
description: Use when writing tests, debugging test failures, reviewing test strategy, or making decisions about what/how to test. Covers TDD workflow, Cucumber/Gherkin conventions, flaky tests, and test suite health.
---

# Testing Philosophy

Principes en conventies voor testen. Het kernprincipe: specs zijn specificaties van verwacht gedrag, geschreven voordat de implementatie bestaat. Niet verificaties achteraf. Dat verschil stuurt alles wat volgt.

## Specs specificeren, ze verifiëren niet

RSpec noemt het een "spec" om een reden: het is een specificatie, niet een test. De spec definieert wat "klaar" betekent voordat er code is geschreven. Zonder die definitie is "klaar" een subjectief oordeel van de implementeur. Code die compileert bewijst syntax. Code die een vooraf geschreven spec passeert bewijst semantiek.

**NOOIT implementatie schrijven voordat je een falende spec hebt gezien.**

Dit is niet optioneel. Dit is niet "waar mogelijk". Dit is ALTIJD, voor elke feature, elke bugfix, en elke interface-wijziging.

**Workflow:**
1. **Red**: Schrijf spec die verwacht gedrag specificeert -> moet FALEN
2. **Green**: Implementeer minimale code om spec te laten slagen
3. **Refactor**: Cleanup met groene specs als vangnet

**Bij bugfixes:**
- Schrijf spec die de bug reproduceert (faalt)
- Fix de bug (spec wordt groen)
- Verifieer door fix te reverten -> spec MOET opnieuw falen

**Bij interface-wijzigingen (renames, kolommen, constructor-signatures):**
- Schrijf de spec met de nieuwe interface (faalt op de oude code)
- Pas de implementatie aan (spec wordt groen)
- "Mechanisch" en "triviaal" zijn geen vrijstellingen

**Dit geldt altijd.** Zelfs voor "triviale" changes. Zelfs voor "urgent" fixes.

**Een uitzondering: puur cosmetische wijzigingen.** CSS classes, kleuren, spacing, font sizes en andere visuele styling hoeven geen TDD dekking. Specs die specifieke CSS classes of design tokens asserteren maken het spec-harnas te rigide voor voortschrijdend design-inzicht. Specificeer het gedrag, niet de presentatie.

**RED -> GREEN -> REFACTOR is een doorlopende flow.** Pauzeer niet tussen fases om toestemming te vragen. Als de gebruiker een opdracht heeft gegeven ("fix dit", "pas dat aan"), doorloop dan de volledige TDD cyclus zonder te stoppen. Het enige pauzemoment is NA de cyclus, wanneer het resultaat klaar is voor review.

## Niet meer doen dan de spec voorschrijft

De spec begrenst het werk. Als er geen spec voor is, bestaat het niet als vereiste. Wil je meer doen? Schrijf eerst een nieuwe spec. Dit voorkomt scope creep, gold plating, en de neiging om "even snel" iets extra's mee te nemen.

## UI/UX bugs krijgen Cucumber scenarios

Wanneer een bug betrekking heeft op gebruikersinteractie (knoppen, formulieren, navigatie, confirm dialogs, statustransities in de browser): schrijf een Cucumber scenario, geen unit spec. Cucumber beschrijft het gedrag vanuit gebruikersperspectief en test de volledige stack inclusief JavaScript.

Unit specs (RSpec requests, model specs) zijn voor server-side logica. Cucumber scenarios zijn voor alles wat een gebruiker ziet en doet.

## Gherkin scenarios zijn domein-documentatie

Feature files beschrijven gedrag in domein-taal, niet UI-interacties. Ze zijn documentatie die toevallig executable is.

**Declaratief (goed):** `When I create a todo "Buy groceries"` -> beschrijft intent, overleeft UI redesigns.
**Imperatief (verboden):** `When I fill in the "title" field with "Buy groceries" And I click the "Add" button` -> breekt bij elke UI wijziging, leest als een testscript in plaats van documentatie.

De UI-mechaniek (welk veld, welke knop, hover voor verborgen elementen) leeft in step definitions, niet in feature files. Als de UI verandert, veranderen alleen step definitions. De scenarios, en daarmee de gedragsdocumentatie, blijven stabiel.

**BRIEF principes:** Business language, Real data, Intention revealing, Essential, Focused, Brief (~5 regels per scenario).

## Spec scaffolding is geen voortgang

Een scenario dat je uitschrijft maar tagt als `@wip` of op een andere manier excludet van de suite, is geen spec. Het is een wensenlijst in code-formaat. Step definitions die alleen `PendingException` throwen zijn cruft bij geboorte.

De TDD-cyclus begint bij Red: een spec die je nooit rood hebt zien draaien heeft de cyclus niet doorlopen. Schrijf een scenario, implementeer de steps volledig, zie het groen worden. Dan het volgende scenario. Nooit meerdere lege scenario's tegelijk aanmaken.

Feature files die alleen uit ongeimplementeerde scenarios bestaan, horen niet te bestaan. Als je nog niet aan die feature toekomt, schrijf er geen spec voor. "De structuur alvast klaarzetten" is planning vermomd als code.

## Red Flags - Je bent aan het rationaliseren

Als je jezelf betrapt op deze gedachten, STOP:
- "Dit is te simpel om te specificeren"
- "Ik schrijf de spec straks wel"
- "Ik zet de structuur alvast klaar"
- "Ik tag het als @wip, dan maken we het later af"
- "Eerst even kijken of het werkt"
- "Laat me de implementatie checken"
- "De user heeft haast"
- "Het is maar een rename"
- "Dit is een mechanische aanpassing"

-> Je bent aan het rationaliseren. Schrijf eerst de spec.

## Spec setup richtlijnen

Minimaliseer spec-level memoization/setup. Geef de voorkeur aan lokale variabelen binnen de spec zelf.

## Main branch is altijd groen

Neem nooit aan dat een spec zou kunnen falen op main. Als het op main staat, slaagt het. Bij het verifiëren van gedrag:
- Schrijf een spec die het verwachte gedrag vastlegt
- Bij het testen van een fix, pas de fix lokaal toe, run de spec, revert dan de fix om de spec te zien falen
- Nooit main uitchecken om "te checken of deze spec daar faalt"
- Bij het refereren naar main, gebruik altijd `origin/main` aangezien lokale main stale kan zijn

## Specs aanpassen is verboden

Een falende spec betekent: fix de CODE, niet de spec. Nooit een spec verzwakken om hem groen te krijgen.

**Uitzondering:** Alleen wanneer requirements daadwerkelijk zijn veranderd, en dan alleen na expliciete bevestiging van de user.

## Demo is geen spec

Handmatige verificatie (demo's, console output, "even proberen") is geen bewijs dat code werkt. Demo output varieert en is niet deterministisch.

**Verboden:** Een applicatie draaien om te verifiëren dat code werkt.
**Verplicht:** Geautomatiseerde specs met voorspelbare input/output.

## Code lezen is geen spec

Source code lezen om te deduceren of iets werkt is geen verificatie. Grep door implementatie vertelt je wat de code doet, niet of het gedrag klopt vanuit gebruikersperspectief. Wanneer de vraag is "werkt X?", is het antwoord een spec die X uitoefent, niet een code review die concludeert dat het zou moeten werken.

**Verboden:** `grep`/`read` door handlers en queries om te concluderen dat een feature werkt.
**Verplicht:** Schrijf een spec die het gedrag vanuit de gebruiker exerceert. De spec is het bewijs.

## Flaky specs zijn een investering

**Definitie van flaky:** Non-deterministische specs die soms groen, soms rood zijn zonder code change.

**Flaky specs zijn NOOIT acceptabel:**
- Kosten alle teamgenoten tijd op alle projecten
- Eroderen vertrouwen in de suite
- Maskeren echte regressies
- Erin investeren om te fixen is altijd de juiste lange termijn beslissing

**Gebruik "flaky" ALLEEN voor non-deterministische specs:**
- Flaky: Spec faalt soms door race condition, timing issue, shared state
- Niet flaky: Spec faalt altijd door missende mock/stub
- Niet flaky: Spec faalt altijd door externe dependency (API, database)
- Niet flaky: Spec faalt altijd door incomplete implementatie

**Wanneer je een flaky spec tegenkomt:**
1. Stop met huidige werk
2. Verzamel context: spec path, command om te runnen, error output, failure rate
3. Stel voor om dedicated onderzoek te starten met volledige context
4. Genereer `claude -p` command met:
   - Spec file path en regel nummer
   - Exact commando om spec te runnen
   - Error output van laatste failure
   - Geschatte failure rate (bijv. "faalt ~30% van de tijd")
   - Hypothese over oorzaak (race condition, timing, shared state, etc.)
5. NOOIT automatisch proberen te fixen tijdens ander werk
6. NOOIT "retry until green" of flakiness maskeren

## Falende specs blokkeren alles

Wanneer de suite failures heeft, is het enige juiste antwoord: fixen. Niet deployen, niet committen, niet "dat zijn pre-existing failures". Falende specs zijn werk, net als warnings. Het maakt niet uit of ze van jouw wijziging komen of al bestonden.

**Verboden:** Deployen of committen voorstellen terwijl de suite failures heeft.
**Verboden:** Failures wegwuiven als "pre-existing" of "niet gerelateerd aan mijn wijziging".
**Verplicht:** Failures onderzoeken, fixen, en de suite groen krijgen voordat je verder gaat.

**Red Flags bij spec failures:**
- "Lijkt niet gerelateerd aan mijn wijzigingen" -> Irrelevant. Het faalt. Fix het.
- "Laat me verifiëren dat het pre-existing is" -> Het doel is fixen, niet schuld toewijzen.
- "Dit is een data-issue, geen [mijn ding]" -> Categoriseren is geen oplossen.
- "Even checken of het op main ook faalt" -> Zelfs als dat zo is, is het nu jouw probleem.
- git stash om te bewijzen dat het "niet van jou" is -> Verkeerde richting. Onderzoek de failure, niet de oorsprong.

**Bij CI-failures die onverwacht breken:** Wanneer je ontdekt dat je wijzigingen specs breken op plekken die je niet had verwacht, is dat een signaal dat er meer onverwachte breakages kunnen zijn. Draai in die situatie de volledige suite voordat je de fix commit. Zeker niet amenden op een vorige commit voordat je weet dat het hele plaatje klopt.

## Mass-verwijderen van tests is een SMELL bij refactors

Wanneer een refactor een API leegmaakt, blijven de gedragingen die de oude tests documenteerden bestaan, alleen ergens anders. De tests moeten daarom mee migreren, niet geschrapt worden. Concreet: verwijder geen reeks tests zonder per testgeval aan te wijzen waar het gedrag nu gedekt is (andere unit-file, cucumber scenario, Playwright script, explicit `it.todo` met verwijzing). Kun je die mapping niet leggen? Dat is geen reden om te dunnen, dat is een blocker: het gedrag is of weg zonder vervanging (regressie), of ongedekt geworden (gat in het veiligheidsnet). Tienregels-diff-groter van je refactor is beter dan een test-crash later. Telt zelfs voor één test wanneer die het enige stuk documentatie is van een gedrag; geldt hard voor elk verwijderingspatroon van meer dan een paar cases tegelijk.
