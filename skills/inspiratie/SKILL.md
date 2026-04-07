---
name: inspiratie
description: Use when tackling unfamiliar topics, designing something new, evaluating approaches, or when the conversation benefits from external perspectives and research. Triggers on questions like "hoe doen anderen dit", "wat bestaat er al", research requests, and unfamiliar domains.
user-invocable: true
---

# Inspiratie

Online onderzoek dat antwoord geeft op: "hoe doen anderen dit?", "wat bestaat er al?", "wat kunnen we leren van gepubliceerde ervaring?" Resultaten vloeien terug in het gesprek als eigen kennis of als discussiepunt.

## Wanneer gebruiken

### Triggers

1. **Expliciet**: `/inspiratie` of `/inspiratie [onderwerp]`
2. **Proactief**: Claude detecteert momenten waarop extern onderzoek waarde toevoegt
3. **Impliciet**: user zegt iets als "hoe doen anderen dit?", "kijk even wat er bestaat", "wat is de standaard aanpak?"

### Proactieve detectiesignalen

- Onbekend terrein (nieuw framework, onbekende standaard, onbekend domein)
- Ontwerpbeslissing met meerdere mogelijke richtingen
- Evaluatieve vraag over een aanpak
- Eerste keer dat een bepaald concept in het gesprek opduikt

### Niet zoeken wanneer

- Routinewerk in een bekend domein
- Vragen puur over de eigen codebase
- User kiest expliciet voor snelheid ("doe maar gewoon", "geen research nodig")

## Diepte

Claude bepaalt op basis van complexiteit en user-signalen. Iteratief: doorzoeken tot er genoeg begrip is.

| Niveau | Wanneer | Zoekrondes |
|--------|---------|------------|
| Snel | Feitelijke vraag, consensus-onderwerp | 1-2 |
| Normaal (default) | Ontwerpvraag, meerdere aanpakken | 2-4 |
| Diep | User signaleert ("diepe duik"), complex domein | 4-8 |

**Diepte verhogen**: "diepe duik", "research dit grondig", "hoe pakken teams dit aan"
**Diepte verlagen**: "snel even checken", "is er een standaard"
**Automatische escalatie**: wanneer eerste ronde tegenstrijdige info of verrassingen oplevert.

## Onderzoekstools

Twee complementaire tools, beide volwaardig:

**WebSearch** voor brede verkenning: wat bestaat er, welke termen gebruiken mensen, welke bronnen komen bovendrijven. Startpunt voor onbekend terrein.

**WebFetch** voor gericht lezen: documentatiepagina's, GitHub discussions, blog posts, Reddit/HN threads, framework-specifieke guides. Gebruik WebFetch wanneer:
- WebSearch een veelbelovende bron oplevert (volledige pagina lezen, niet alleen snippet)
- Je al weet waar de informatie staat (officiele docs, bekende community's)
- Je dieper wilt graven in een specifiek perspectief of implementatie

WebFetch is geen bijzaak van WebSearch. Soms is WebFetch het startpunt (bekende documentatie-URL).

## Workflow

```
1. FORMULEER
   - Leid onderwerp af (uit argument of conversatiecontext)
   - Check eerst lokale codebase (Grep/Glob) op bestaande patronen
   - Bepaal startniveau (snel/normaal/diep)
   - Formuleer 1-3 initiele zoekvragen
   - Identificeer bekende bronnen die direct via WebFetch bereikbaar zijn

2. ZOEK
   - WebSearch voor brede verkenning
   - WebFetch voor directe bronnen (docs, GitHub, forums)
   - WebFetch voor diepere lezing van veelbelovende zoekresultaten
   - Parallelliseer onafhankelijke zoekacties

3. EVALUEER
   - Consensus of diversiteit?
   - Verrassingen of tegenspraken?
   - Voldoende info voor het diepteniveau?

   Nee -> herformuleer, verhoog diepte, terug naar 2
   Ja -> door naar 4

4. BEPAAL OUTPUT MODUS
   - Absorberen of Bespreken? (zie onder)
```

## Output modus

### Absorberen (geen discussie)

Wanneer:
- Duidelijke consensus-aanpak gevonden
- Bevestigt huidige richting
- Eenduidig antwoord op feitelijke vraag

Actie: kort noemen wat je gevonden hebt, toepassen, doorwerken. Geen rapport, geen opsomming van bronnen.

### Bespreken (opties voorleggen)

Wanneer:
- Meerdere valide benaderingen met echte trade-offs
- Keuze hangt af van projectspecifieke factoren

Actie: beknopt presenteren met trade-offs en bronnen. Geen uitputtende lijst, alleen de opties die er echt toe doen. **Rangschik op kwaliteit van het eindresultaat, niet op implementatiegemak.** "De snelste weg" is geen aanbeveling, "de meest kansrijke" wel. Criteria: nauwkeurigheid, uitbreidbaarheid, community/momentum, en hoe goed het de user's einddoel dient.

### Bespreken (richting uitdagen)

Wanneer:
- Bevindingen stellen huidige aanpak in vraag
- Significante risico's of anti-patterns ontdekt

Actie: presenteren als tegenspraak. Sluit aan bij de evaluatieve-vragen-regel in CLAUDE.md.

## Interactie met plan mode

In plan mode: bevindingen als context-sectie in het plan opnemen, niet als losse output.
Buiten plan mode: direct toepassen of bespreken, afhankelijk van output modus.

## Red Flags

Als je jezelf betrapt op een van deze gedachten, is dat het signaal dat je WEL moet zoeken:

| Gedachte | Realiteit |
|----------|-----------|
| "Mijn kennis is waarschijnlijk accuraat genoeg" | Waarschijnlijk is niet zeker. Zoek het op. |
| "Dit is een stabiel protocol/framework, dat verandert niet" | Stabiel betekent niet dat jouw kennis compleet is. |
| "Voor een architectuur gesprek is research niet nodig" | Architectuur gesprekken zijn JUIST waar research het meest oplevert. |
| "Ik kan dit beantwoorden vanuit mijn training" | Dat kan, maar mis je dan niet bestaande libraries, community patterns, of bekende valkuilen? |
| "Dit is te simpel om op te zoeken" | Simpele vragen hebben vaak verrassend genuanceerde antwoorden. |
| "Research vertraagt het gesprek" | Een verkeerde richting kost meer tijd dan 30 seconden zoeken. |
| "Ik zoek straks wel als het nodig is" | Het is nu nodig. De vraag is gesteld. |
| "X is de snelste weg" | Snelste weg is niet de beste weg. Rangschik op kwaliteit van het eindresultaat. |
| "X is de winnaar want het draait in de browser" | Implementatiegemak is geen kwaliteitscriterium. Wat levert het beste resultaat? |

**De kernregel**: wanneer je twijfelt of je moet zoeken, is dat het bewijs dat je moet zoeken. Twijfel = onzekerheid = research nodig.
