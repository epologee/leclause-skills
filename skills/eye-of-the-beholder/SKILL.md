---
name: eye-of-the-beholder
user-invocable: false
description: Use when producing or reviewing any visual layout (screen, print, responsive). Also use when the user shares a screenshot with spacing concerns. Activates DURING and AFTER layout CSS work. Catches cramped text, missing margins, disproportionate spacing.
---

# Eye of the Beholder

## Het echte probleem

Claude schrijft CSS en kijkt pas aan het eind naar het resultaat. En wanneer Claude kijkt, kijkt het bevestigend ("ik schreef padding, dus er is ruimte") in plaats van observerend ("wat zie ik?"). Een designer kijkt honderd keer tijdens het proces. Claude kijkt een keer.

De oplossing is niet meer regels. De oplossing is vaker kijken, en anders kijken.

## De kern: observatie voor verklaring

**Na elke layout-wijziging: screenshot. Beschrijf wat je ziet VOORDAT je terugkijkt naar de CSS.**

Niet: "de padding zou 0.6rem moeten zijn, ik zie ruimte, klopt."
Wel: "ik zie tekst die tegen de bovenkant plakt." Dan pas: waarom? Welke CSS veroorzaakt dit?

Dit is het verschil tussen bevestigend kijken en observerend kijken. Een arts beschrijft eerst het symptoom, dan pas de diagnose. Een designer ziet eerst het resultaat, dan pas de code.

## Wanneer

Bij visueel werk is deze skill niet iets dat je aan het eind aanroept. Het is een werkwijze:

1. **Schrijf een blok layout CSS** (een container, een sectie, een pagina-structuur)
2. **Screenshot** (zelf nemen of van de user ontvangen)
3. **Beschrijf wat je ziet** in de screenshot, zonder naar de CSS te kijken. Scan kloksgewijs: boven -> rechts -> onder -> links. Benoem per rand het dichtstbijzijnde element.
4. **Vergelijk observatie met intentie.** Plakt er iets? Voelt iets krap? Is er een leegte?
5. **Fix en herhaal** vanaf stap 2.

Dit is design-TDD: de screenshot is de test, de CSS is de implementatie.

## Hoe te kijken

Wanneer je een screenshot bekijkt (zelf genomen of aangeleverd), stel deze vragen in deze volgorde:

**Eerst voelen, dan meten:**

1. **Knijp je ogen dicht.** Wat springt eruit? Waar voelt het krap? Waar voelt het leeg? Waar stopt je oog? Dit is Gestalt in actie: het brein ziet groepering, nabijheid, en spanning sneller dan het bewuste denken.

2. **Trace de randen.** Boven -> rechts -> onder -> links. Wat is het dichtstbijzijnde element aan elke rand? Hoeveel ruimte zit ertussen? Raakt iets de rand?

3. **Zoek het ritme.** Zijn de afstanden tussen herhalende elementen (secties, kaarten, regels) consistent? Wordt het ritme ergens gebroken?

4. **Zoek de vreemde eend.** Is er een element dat net anders is dan de rest? Iets dat bijna hetzelfde is maar niet helemaal? Dat is waarschijnlijk een bug, geen variatie.

5. **Benoem elke aanraking.** Welke elementen raken elkaar? Welke elementen raken een rand? Welke elementen vallen buiten hun container? Lijst ze op. Voor elk: is dit intentioneel? Een border die de container raakt is meestal bewust. Tekst die de paginarand raakt is dat bijna nooit. Bewuste aanrakingen zijn expliciet (bijv. een `bleed` class), onbewuste zijn bugs.

6. **Vergelijk links met rechts, boven met onder.** Is de compositie in balans? Niet per se symmetrisch, maar intentioneel?

7. **Hoe wordt dit vastgehouden?** Het ontwerp grenst aan de fysieke wereld. Papier wordt vastgehouden met vingers die de randen bedekken. Een telefoonscherm heeft bezels (of niet meer). Een laptop heeft een rand. De marges van het ontwerp moeten rekening houden met wat de gebruiker fysiek bedekt.

**Tschichold's margeverhoudingen voor gedrukt werk: 1:1:2:3** (binnen:boven:buiten:onder). De onderste marge is het grootst omdat handen daar het papier vasthouden. Het Van de Graaf canon uit middeleeuwse manuscripten: 2:3:4:6. Dezelfde logica, nog dramatischer.

**Het medium muteert.** Smartphone bezels waren vroeger dik, nu bijna onzichtbaar. Toen bezels dik waren, hoefde de UI-marge niet groot te zijn (vingers raakten plastic, niet pixels). Nu bezels weg zijn, bedekken vingers de interface, dus moeten UI-marges groter. Apple's safe area insets groeiden mee met krimpende bezels. Voor print geldt het omgekeerde: papier heeft geen bezel, alleen papier. De "bezel" is nul, dus de marge moet alles compenseren.

**Praktisch:** voor een los A4-vel dat in handen wordt gehouden, zijn de buitenste en onderste marges het belangrijkst. Een recept op het aanrecht wordt bovenaan of aan de zijkant vastgehouden. De marges moeten groot genoeg zijn dat vingers geen tekst bedekken.

**Dan pas meten en fixen:**

Druk problemen uit als verhoudingen, niet als pixels:
- "De titel zit op 0px van de bovenkant, maar de body font is 12px. Daar hoort minimaal 2.5x fontgrootte (~30px) te zitten."
- "De sectie-gap is 14px maar de interne gap is 5px. Dat is een 2.8:1 ratio, helder genoeg."
- "Dit is een geprint A4-vel. Tschichold's ratio 1:1:2:3 geeft bij 1.5cm basis: boven 1.5cm, binnen 1.5cm, buiten 3cm, onder 4.5cm."

## Fundament

**Robin Williams (CRAP):** Contrast (maak verschil onmiskenbaar of maak het gelijk), Repetition (herhaal visuele keuzes voor samenhang), Alignment (alles moet visueel verbonden zijn met iets anders), Proximity (nabijheid impliceert relatie).

**Gestalt (Wertheimer, Koffka):** Het brein zoekt de eenvoudigste interpretatie (Pragnanz). Gelijke elementen worden als groep gezien (Similarity). Dit is waarom een 12-jarige spacing-problemen "ziet" en Claude niet: het brein doet het automatisch, Claude moet het bewust doen.

**Muller-Brockmann (Grid Systems):** Alle spacing-waarden afleiden van een gedeelde basis. Het grid is een discipline die willekeur voorkomt.

**Tufte:** Maximaliseer de data-ink ratio. Elk visueel element moet bijdragen aan begrip. **Tschichold:** Witruimte is een actief ontwerpelement, niet wat overblijft.

## Veelvoorkomende blinde vlekken

| Wat Claude doet | Wat er misgaat |
|-----------------|----------------|
| `padding: 0.6rem 0` schrijven | De 0 is nul ruimte links/rechts. Lees elke waarde. |
| Element buiten de hoofdcontainer plaatsen | Dat element erft geen padding. Het heeft eigen spacing nodig. |
| Naar het midden kijken, niet naar de randen | Het midden ziet er altijd goed uit. De fouten zitten aan de randen. |
| "Past het?" als evaluatiecriterium | Fit is niet kwaliteit. Iets kan passen en er tegelijk lelijk uitzien. |
| Een fix doen en stoppen | Elke fix triggert een rescan van alle vier de randen. |
| CSS lezen als bewijs | CSS beschrijft intentie, niet resultaat. De screenshot is de waarheid. |
| Fontsizes verkleinen om te passen | Krimpen is altijd fout. Herstructureer de layout. |

## Output

Na het bekijken van een screenshot:

```
Observatie (voor ik naar de CSS kijk):
- Boven: de titel raakt de bovenkant van de pagina
- Rechts: voldoende ruimte
- Onder: ~25% wit onderaan, voelt leeg
- Links: de titel begint verder links dan de step-content
- Ritme: stappen zijn gelijkmatig verdeeld
- Vreemde eend: stap 3 heeft minder content, voelt smaller

Diagnose (na CSS check):
- .print-header heeft padding: 0.6rem 0 (nul links/rechts)
- .print-header heeft geen margin-top (plakt aan content-area top)

Fix:
- padding: 0.6rem 0.9rem (0.9rem = 3x basisunit, gelijk aan .main padding-x)
```
