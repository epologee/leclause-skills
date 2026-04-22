---
name: eye-of-the-beholder
user-invocable: true
description: Use when producing or reviewing any visual layout, color system, or animation (screen, print, responsive, transitions). Also use when the user shares a screenshot or screen recording with spacing, contrast, color-token, or timing concerns. Activates DURING and AFTER layout CSS, color token, contrast, or animation work. Catches cramped text, missing margins, disproportionate spacing, broken WCAG contrast, ad-hoc token use, snapping transitions, out-of-sync animations, and content that disappears before its container does.
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

1. **Schrijf een blok layout CSS of een transitie** (een container, een sectie, een pagina-structuur, een state-overgang)
2. **Screenshot of recording** (zelf nemen of van de user ontvangen). Voor transities: een GIF/MP4 of een reeks frames uit een headless browser.
3. **Beschrijf wat je ziet** in het resultaat, zonder naar de CSS te kijken. Scan kloksgewijs: boven -> rechts -> onder -> links. Benoem per rand het dichtstbijzijnde element. Voor animaties: herhaal de scan op start-, mid-, en eind-frame.
4. **Vergelijk observatie met intentie.** Plakt er iets? Voelt iets krap? Is er een leegte? Snapt er iets terwijl de rest animeert?
5. **Fix en herhaal** vanaf stap 2.

Dit is design-TDD: het rendered resultaat is de test, de CSS is de implementatie.

## Hoe te kijken

Wanneer je een screenshot bekijkt (zelf genomen of aangeleverd), stel deze vragen in deze volgorde:

**Eerst voelen, dan meten:**

1. **Knijp je ogen dicht.** Wat springt eruit? Waar voelt het krap? Waar voelt het leeg? Waar stopt je oog? Dit is Gestalt in actie: het brein ziet groepering, nabijheid, en spanning sneller dan het bewuste denken.

2. **Trace de randen.** Boven -> rechts -> onder -> links. Wat is het dichtstbijzijnde element aan elke rand? Hoeveel ruimte zit ertussen? Raakt iets de rand?

   **Trace is fractaal.** Doe dit op elk niveau waar iets een rand heeft:
   - Pagina vs. viewport
   - Container vs. parent padding
   - Component vs. eigen border/padding
   - Glyph of icon vs. viewBox of bounding box
   - Path/stroke vs. pixel-grid

   Dezelfde regels werken op elk niveau. Een icoon dat in zijn viewBox wordt geclipt is hetzelfde probleem als een titel die de paginarand raakt, alleen een zoomstap dieper.

3. **Zoek het ritme.** Zijn de afstanden tussen herhalende elementen (secties, kaarten, regels) consistent? Wordt het ritme ergens gebroken?

   **Interne ritmiek is een apart oordeel.** Perimeter-padding meten ("content staat 32px van de rand") is niet hetzelfde als sibling-gaps meten. Loop binnen de container langs elk visueel blok (titel, paragraaf, tabel, lijst, citaat, signature, footer) en benoem de verticale ruimte tussen elk aangrenzend paar. Raken twee blokken elkaar? Is de gap kleiner dan de line-height van de body-font? Zijn de gaps onderling consistent? Een kaart met royale buitenmarges maar geplette interne blokken leest niet als document; het leest als gedumpte tekst in een doos. Dit is "collapsed padding": de buitenrand is in orde, de binnenhuishouding niet. Margin-collapse door de container-padding heen is een bekend mechanisme (eerste kind-margin collapseert door parent-padding-top als de parent geen border/padding/inline-content heeft boven het kind); als je dit vermoedt, check met DevTools of fix met `display: flow-root` / een expliciete border-top.

4. **Zoek de vreemde eend.** Is er een element dat net anders is dan de rest? Iets dat bijna hetzelfde is maar niet helemaal? Dat is waarschijnlijk een bug, geen variatie.

5. **Benoem elke aanraking.** Welke elementen raken elkaar? Welke elementen raken een rand? Welke elementen vallen buiten hun container? Lijst ze op. Voor elk: is dit intentioneel? Een border die de container raakt is meestal bewust. Tekst die de paginarand raakt is dat bijna nooit. Bewuste aanrakingen zijn expliciet (bijv. een `bleed` class), onbewuste zijn bugs.

6. **Glyph- en icoon-check.** Voor elk vector-icoon of glyph in de screenshot: past de inhoud binnen zijn eigen container? Een icoon dat aan één rand "afgesneden" voelt is bijna altijd een path die buiten zijn viewBox loopt. SVG heeft default `overflow: hidden`, dus de clip is stilletjes. Voor stroke-based iconen: tel de halve stroke-width op bij de path-bounds (bij `stroke-width="1.5"` ligt de werkelijke rand op `coördinaat ± 0.75`). Fix altijd door viewBox groter of path kleiner, nooit door `overflow="visible"` (dat verplaatst het probleem naar de parent).

7. **Optische vs. mathematische bounds.** Cirkels, driehoeken en ronde glyphs wegen optisch minder dan vierkanten met dezelfde mathematische bounds. Designers compenseren met *overshoot*: een "O" is fractioneel groter dan een "H", een cirkel moet ~113% van een vierkant zijn om even groot te lezen, een driehoek moet met zijn scherpe punt buiten de baseline steken. Voelt een ronde vorm "kleiner" dan een vierkante buur van dezelfde pixel-grootte? Dat is geen illusie, dat is een ontbrekende overshoot.

8. **Optisch centrum zit hoger dan geometrisch centrum (Arnheim).** Mathematisch gecentreerde content voelt top-heavy. Duw het visuele zwaartepunt 2-5% omhoog. Dit is waarom `align-items: center` in CSS vaak "net te laag" aanvoelt, het is mathematisch correct, niet optisch correct.

   **Uitzondering voor typografie in iconen-containers** (buttons, pills, badges): hier werkt de regel *omgekeerd*. Een digit of letter zit van nature al hoog binnen zijn line-box omdat font ascent groter is dan font descent (typisch 80/20). Cap-height center zit ~5% boven em-box center. Bij een pill met SVG-icoon dat wél symmetrisch is, voelt de tekst "te hoog" (meer witruimte eronder dan erboven). Spiekermann's regel: *align op cap-height center, niet op glyph bounding box*. Fix via micro-translate (~0.5-1px) of via `text-box-trim` / cap-height line-height libraries (Braid's capsize). Bij een review: zie je tekst en icoon die niet gelijk gecentreerd voelen in hun container, met tekst hoger dan icoon? Dat is font metric asymmetry, niet je brein.

9. **Vergelijk links met rechts, boven met onder.** Is de compositie in balans? Niet per se symmetrisch, maar intentioneel? Symmetrische compositie voelt vaak saai; asymmetrische balans via visuele weging (kleur, contrast, massa) is levendiger (Arnheim).

10. **Hoe wordt dit vastgehouden?** Het ontwerp grenst aan de fysieke wereld. Papier wordt vastgehouden met vingers die de randen bedekken. Een telefoonscherm heeft bezels (of niet meer). Een laptop heeft een rand. De marges van het ontwerp moeten rekening houden met wat de gebruiker fysiek bedekt.

**Tschichold's margeverhoudingen voor gedrukt werk: 1:1:2:3** (binnen:boven:buiten:onder). De onderste marge is het grootst omdat handen daar het papier vasthouden. Het Van de Graaf canon uit middeleeuwse manuscripten: 2:3:4:6. Dezelfde logica, nog dramatischer.

**Het medium muteert.** Smartphone bezels waren vroeger dik, nu bijna onzichtbaar. Toen bezels dik waren, hoefde de UI-marge niet groot te zijn (vingers raakten plastic, niet pixels). Nu bezels weg zijn, bedekken vingers de interface, dus moeten UI-marges groter. Apple's safe area insets groeiden mee met krimpende bezels. Voor print geldt het omgekeerde: papier heeft geen bezel, alleen papier. De "bezel" is nul, dus de marge moet alles compenseren.

**Praktisch:** voor een los A4-vel dat in handen wordt gehouden, zijn de buitenste en onderste marges het belangrijkst. Een recept op het aanrecht wordt bovenaan of aan de zijkant vastgehouden. De marges moeten groot genoeg zijn dat vingers geen tekst bedekken.

**Dan pas meten en fixen:**

**Meten én oordelen is één handeling, niet twee.** Een pixel-waarde opschrijven is geen voltooide observatie; pas wanneer die waarde is getoetst aan een standaard of ratio, is de bevinding compleet. "Er zit 20px padding" is een halve zin. "20px padding op 14px body-font = 1.4x, onder de 2.5x drempel voor comfortabele document-leesruimte" is een bevinding. De scan eindigt pas wanneer elke gemeten waarde een uitgesproken oordeel heeft: goed, krap, ruim, faalt.

**Default ratios om tegen te toetsen:**
- Padding/gutter rond body-tekst: minimaal 2.5x body-font size. Onder die drempel voelt het krap, ook als het niet plakt.
- Document-metafoor canvases (email-body, card-as-paper, editor-surface): Tschichold 1:1:2:3 (binnen:boven:buiten:onder) als startpunt. Web-style 16-24px rondom kwalificeert niet; een document wil 2-3rem+ ruimte rondom de tekst.
- Sectie-gap vs interne gap: minimaal 2x verschil om hiërarchie te leveren. "14px vs 5px = 2.8:1" werkt; "14px vs 10px = 1.4:1" is ambigu.
- Aangrenzende surface-niveaus: minimaal 1.07x luminance ratio (zie kleur-sectie).

Druk problemen uit als verhoudingen, niet als pixels:
- "De titel zit op 0px van de bovenkant, maar de body font is 12px. Daar hoort minimaal 2.5x fontgrootte (~30px) te zitten."
- "De sectie-gap is 14px maar de interne gap is 5px. Dat is een 2.8:1 ratio, helder genoeg."
- "Dit is een geprint A4-vel. Tschichold's ratio 1:1:2:3 geeft bij 1.5cm basis: boven 1.5cm, binnen 1.5cm, buiten 3cm, onder 4.5cm."
- "Email-body kaartje heeft 20/24px padding op 14px body-font = 1.4x/1.7x. Onder 2.5x drempel, en ver onder Tschichold voor document-canvas. Krap."

## Kleur: dezelfde discipline, andere as

Ruimte is één as waarop je observerend kijkt. Kleur is een tweede. Dezelfde houding werkt: niet "deze twee cells hebben allebei een border dus ze zijn gescheiden" maar "zie ik het verschil?" Niet "er staat `text-muted` dus de tekst is leesbaar" maar "kan ik dit comfortabel lezen zonder te turen?"

### Visuele kleur-observatie

Voeg deze vragen toe aan de scan in "Hoe te kijken":

11. **Hoeveel grijstinten zie je?** Tel ze in de screenshot. Een gedisciplineerd systeem heeft er weinig en consistent gebruikt. Tien subtiele varianten is geen subtiliteit, het zijn tien losse keuzes die toevallig in dezelfde repo wonen.

12. **Aangrenzende oppervlakken.** Staan twee "verschillende" surfaces naast elkaar (canvas vs. list pane, list vs. detail)? Zie je het onderscheid direct, of moet je zoeken? Als je moet zoeken, is de luminance-delta te klein. Dit is vooral een val in dark mode.

13. **Kun je secundaire tekst lezen zonder te turen?** Metadata, timestamps, captions. Als je het instinctief vergroot of dichterbij schuift, faalt het WCAG AA niveau. Dat is geen smaakkwestie maar een structurele fout.

14. **Waarschuwings- en statuskleuren.** Zijn "rood voor fout" en "groen voor ok" duidelijk genoeg? Failure text op een witte achtergrond moet AA halen, net als body text. Tailwind's `red-500` en `green-500` halen dat meestal net niet op wit. Donkerder (`red-700`, `green-700`) wel.

### Onder de screenshot kijken: het tokensysteem

Een screenshot kan er prima uitzien terwijl het systeem eronder rommelig is. Drie audits die je op code-niveau doet, niet op beeld:

**1. Token-vocabulaire scan.** Grep in de component-laag naar de omzeilings-patronen:

- Opacity modifiers op kleur-utilities (Tailwind `text-foo/50`, `bg-foo/20`): meestal een teken van een missende tint, niet een bewuste opacity. Developer had een derde tekstniveau nodig en er bestond er maar twee.
- Palette-kleuren in app-code (`text-red-500`, `bg-blue-200`): omzeilt het semantische systeem. Elk gebruik is een vraag "waarom had `text-danger` hier niet gewerkt?"
- Hardcoded hex/rgb/oklch in style blocks (`color: #94a3b8`): frameworkloze escape. Meestal omdat het tokensysteem geen passend woord had.
- Undefined tokens die wel worden gebruikt (`bg-surface-muted` terwijl dat token niet bestaat): Tailwind v4 genereert dan geen class en valt stilletjes leeg terug. Zie je een lege achtergrond waar je kleur verwacht, check de theme definitie.

Elk van deze patronen signaleert een onvolledig tokensysteem. De fix is zelden "voeg een token toe" (reactief, herhaal probleem). De fix is "herzie de vocabulaire tot elke rol die in de UI voorkomt een eigen naam heeft."

**2. WCAG contrast math.** Voor elke gebruikte tekstkleur op elke gebruikte achtergrond, bereken de ratio. Je hoeft niet te turen; de wiskunde geeft het definitieve antwoord.

Voor de AA/AAA drempel-tabel in het Engels, inclusief de argumentatie achter 4.5:1 en 3:1, zie impeccable's `reference/color-and-contrast.md`. De formule hieronder blijft hier omdat observationeel werk vaak ter plekke een ratio moet berekenen zonder tool-wissel.

WCAG 2.1 SC 1.4.3 formule:

```
Per kanaal c (R, G, B):
  c_norm = c / 255
  c_lin  = c_norm ≤ 0.03928 ? c_norm / 12.92 : ((c_norm + 0.055) / 1.055)^2.4

Luminance:
  L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin

Ratio van twee kleuren:
  ratio = (L_lichter + 0.05) / (L_donkerder + 0.05)
```

Drempels:

| Gebruik                                         | AA     | AAA  |
| ----------------------------------------------- | ------ | ---- |
| Body text (< 18pt regular, < 14pt bold)         | 4.5:1  | 7:1  |
| Large text (≥ 18pt, of ≥ 14pt bold)             | 3:1    | 4.5:1 |
| UI component boundary (button, input, control)  | 3:1    | -    |
| Decoratieve dividers / non-functional borders   | vrijgesteld | -    |

Een klein scriptje in Ruby, Python of JavaScript scheelt uren visuele twijfel. Draai het voor elke fg/bg combinatie die de app daadwerkelijk gebruikt, niet voor alle theoretische combinaties.

**3. Perceptuele surface-delta.** Aangrenzende surface-niveaus (canvas, list pane, detail pane, hover, active) moeten visueel onderscheidbaar zijn. Minimum: **1.07x luminance ratio** tussen aangrenzende niveaus. Onder die drempel pretendeert het systeem hiërarchie die er optisch niet is.

Dit is vooral een val in dark mode. Absolute luminance-waarden zijn daar klein (typisch 0.003 - 0.02), dus een absolute delta van 0.004 ziet er in een spreadsheet substantieel uit maar is perceptueel nul. Check altijd de ratio, niet het verschil.

**Light en dark zijn twee ontwerpen, niet één.** Als je een rol (`surface-1`) licht goed invult en dan dark mode "wel ergens donker" maakt, heb je twee verschillende semantische systemen die toevallig dezelfde naam delen. Elke rol moet in beide modes dezelfde betekenis dragen: als `surface-1` in licht het meest prominente leesoppervlak is, moet hij dat in donker ook zijn. Gebruik `light-dark(licht, donker)` in CSS custom properties zodat beide waarden naast elkaar staan in dezelfde regel en niet uit elkaar drijven.

## Animatie: dezelfde discipline, tijd als as

Ruimte en kleur zijn twee assen. Tijd is een derde. Dezelfde houding werkt: niet "ik schreef een `transition: transform 200ms`, dus het animeert soepel" maar "wat zie ik tussen frame 0 en frame 12?" De screenshot wordt een *serie* screenshots. De randen-trace gebeurt op elk key-frame. Het ritme is de timing-curve. De "vreemde eend" is het ene element dat uit de maat valt.

Een statisch eindbeeld dat klopt zegt niets over de reis ernaartoe. Een UI die voor en na het animeren keurig gelayout is kan ertussenin lelijk kapseizen.

### Visuele animatie-observatie

Voeg deze vragen toe aan de scan in "Hoe te kijken". Ze worden toegepast op een *reeks* frames (start, kwart, half, drie-kwart, eind) in plaats van op één screenshot:

15. **Bewegen alle elementen die samen horen als één?** Wanneer een header en zijn content allebei op nieuwe posities eindigen, moeten ze tijdens de transitie hetzelfde *tempo* hebben. Snapt de header terwijl de content animeert, of stopt de ene bij 80% terwijl de ander bij 60% is? Dit is ritme op de tijd-as. Een component dat uit de maat loopt is de "vreemde eend" van animatie.

16. **Wat gebeurt er met verdwijnende content?** Vervalt een element instant terwijl zijn container nog beweegt? Dat is een "teleporting element": het vertrekt voordat zijn vervoermiddel vertrokken is. Je verwacht dat content meereist tot de rit eindigt. Fix patroon: `transition: visibility 0s linear var(--duration)` op de hidden-state zodat de visibility-flip pas NA de beweging plaatsvindt. Spiegelbeeld: verschijnt content pas nadat zijn container al bewogen is? Dan is de entry gebroken, de visibility moet dan juist instant flippen.

17. **Begint en eindigt alles op hetzelfde moment?** Check de transition delay, duration en easing van elk animerend element via `getComputedStyle`. Verschillende durations zijn soms intentioneel (stagger) maar vaker een bug. "Nav snapt, content animeert 200ms" is zelden expressief, meestal een vergeten `transition` regel op de nav.

18. **Is een cell die "hidden" is echt weg of alleen onzichtbaar?** Off-screen parken (visibility hidden bij volledige renderWidth) en collapsen naar 0 (width 0, display none) zien er op een statische screenshot hetzelfde uit. Onder beweging niet: een geparkeerde cell kan als één geheel mee-schuiven met de rest, een gecollapste cell snapt weg. Voor slide-achtige transities: park, niet collapse.

19. **Timing versus afstand.** Een transitie van 200ms voelt snel voor een 50px shift en traag voor een 800px shift. Als er meerdere transities tegelijk lopen met verschillende afstanden, wordt dit zichtbaar. De vraag is niet "is de duration goed?" maar "klopt de SNELHEID (px/ms) voor wat ik vertel?" In grote column-shifts is een kortere duration soms expressiever dan hetzelfde 200ms dat je overal gebruikt.

### Onder de screenshot kijken: timing en sync

Een transitie kan er goed uitzien op één frame maar onder de motorkap uit sync zijn. Code-niveau audits, zoals bij de token-vocabulaire scan:

**1. Timing-bron scan.** Grep naar hardcoded durations en easings in component code:

- Numerieke ms/s waarden in CSS (`200ms`, `0.3s`): meestal een ontbrekende custom property. Als twee elementen in dezelfde flow animeren en beiden apart `200ms` hardcoden, drijven ze bij de eerste refactor uit elkaar.
- Hardcoded cubic-bezier of named ease (`ease`, `ease-out`, `cubic-bezier(...)`): zelfde probleem. Definieer een `--duration-*` en `--ease-*` vocabulaire en gebruik die overal.
- `transition: all`: bijna altijd fout. "All" inclusief properties die je niet wilde animeren (kleur, border) en properties die layout triggeren (width, padding). Wees expliciet: `transition: transform var(--duration) var(--ease), opacity ...`.
- Svelte/React animation libs op plekken waar CSS-transition volstaat: extra bundle, extra concept, meestal niet nodig voor state-to-state transitions.

**2. Sync-audit.** Voor een flow waar meerdere elementen samen moeten bewegen: lijst expliciet op wat wel en wat niet transitioneert. Een element dat een inline `style:width` krijgt zonder `transition` regel erop is een snapping element. Dat is het ene snelle controlepatroon dat je zelf via `grep -n "style:" --include="*.svelte"` kunt draaien.

**3. Compositor-only properties.** Transform en opacity worden door de compositor geanimeerd zonder layout. Width, top, left, padding, margin zijn layout-properties en triggeren reflow per frame. Voor kleine elementen is dat fine. Voor rijen van 5+ items of bij parallelle transities kan het janken. `contain: layout` op animerende children isoleert de reflow tot hun eigen box. `will-change: transform` (niet `will-change: width`, dat is een anti-pattern per MDN) promoot de strip naar een eigen layer.

De normatieve regel "transform en opacity only" voor animaties staat ook in impeccable's `reference/motion-design.md`. Wat hier blijft: de observationele diagnose (reflow-check op rijen, `contain: layout` als tactisch fix, `will-change: width` als specifieke anti-pattern) omdat die gaan over hoe je een bestaand probleem herkent, niet over welke regel je volgt tijdens het bouwen.

### Zelf opnemen en dissecten

Een animatie verifieren zonder hem op te nemen is hetzelfde als een layout verifieren zonder screenshot. Workflow:

**1. Reproduce.** User levert een GIF of MP4, OF je neemt zelf op. Zelf opnemen kan via:

- **Headless browser test driver** (Cuprite, Playwright): `session.driver.save_screenshot(path, full: true)` in een loop met `sleep` ertussen, of sequentiele snapshots met expliciete viewport resizes.
- **Screen recording** (macOS: CleanShot, Cmd+Shift+5): snel maar handmatig.
- **Chrome DevTools Recorder**: structureel, als je een user flow wilt reproduceren.

Sla de recording op in `tmp/` of een scratch map die gitignored is.

**2. Dissect.** Frame extraction via `ffmpeg`:

```bash
ffmpeg -i capture.mp4 -vf "fps=15,scale=900:-1" /tmp/frame_%03d.png
```

`fps=15` is genoeg voor 200-400ms transities (3-6 frames over de animatie). `scale=900:-1` houdt de file sizes klein zodat de Read tool de frames kan inzien. Voor langere of subtielere animaties: verhoog naar `fps=30` en leef met de grotere files.

Read de frames via de Read tool. Per frame: doe de scan-vragen uit "Hoe te kijken" (randen, ritme, vreemde eend). Vergelijk frame N met frame N+1: wat is veranderd, wat had niet mogen veranderen, wat had WEL moeten veranderen?

**3. Self-capture verificatie**. Na een fix: zelf een nieuwe recording maken om te bewijzen dat het probleem weg is. Dezelfde workflow.

**4. Mid-animation inspection.** Rest-state screenshots bewijzen alleen de eindposities, niet de reis. Voor tussentijdse inspectie:

- **Slow-mo truc**: override de duration custom property via JS in een test: `document.querySelector('.root').style.setProperty('--duration', '1s')`. Trigger de transitie, sleep 100-500ms, sample `getComputedStyle(element).transform` of `.visibility`. De 5x of 10x vertraging geeft je een ruim venster om mid-animation waardes te lezen.
- **Multiple samples**: op t=50, 100, 150, 200ms een snapshot, verifieer dat de waardes monotoon interpoleren en dat samenhorende elementen op elk sample punt in sync zijn.

**5. Rest-vs-mid testing**. Een animatie-test die alleen rest-state checkt is gebroken per definitie: hij kan niet falen op de helft-van-de-animatie bugs waar de klant last van heeft. Schrijf expliciet een mid-animation assertie als het kritisch is dat elementen synchroon lopen. De slow-mo truc maakt dat schrijfbaar in Cucumber/Playwright zonder race conditions.

### Pixel-level animatie-sampling

Wanneer je frames visueel bekijkt en de bewegingen ogen "ongeveer goed" of je kunt niet zien of een progress van 10% naar 5% terugtrekt, dan komt dat door het image-viewer limiet: een 4px-brede bar over een 60px-hoge rij rendert 5% verschil als 3 pixels. Op een schaal-gecomprimeerde image-view zie je dat niet. Je moet dan direct de pixel-data uit de frames lezen.

**Techniek**: ffmpeg extract een 1-pixel brede verticale slice op de bar-positie, per frame. Decode de raw RGB bytes uit een PPM-header. Classificeer elke pixel als `P` (paars/selected), `A` (amber/unread), `.` (background) op basis van RGB-drempels. Count de P en A pixels per frame om een exact percentage te krijgen.

```javascript
const { execSync } = require('child_process')
const fs = require('fs')

const X = 29  // bar x-positie in de GIF (meet vooraf via één slice)
const gif = '/tmp/capture.gif'

function classify(r, g, b) {
  if (b > 150 && r < 180) return 'P'                    // paars/violet
  if (r > 200 && g > 140 && g < 190 && b < 120) return 'A'  // amber
  if (r > 200 && g > 200 && b > 200) return '.'         // background
  return '?'                                             // transitiestate
}

for (let n = 0; n < 50; n++) {
  execSync(`ffmpeg -y -v error -i ${gif} -vf "select=eq(n\\,${n}),crop=1:206:${X}:0" -vframes 1 /tmp/slice-${n}.ppm`)
  const buf = fs.readFileSync(`/tmp/slice-${n}.ppm`)
  // PPM: P6\n<w> <h>\n<max>\n<binary>
  const headerEnd = buf.indexOf(0x0a, buf.indexOf(0x0a, buf.indexOf(0x0a) + 1) + 1) + 1
  const pixels = buf.slice(headerEnd)
  const cells = []
  for (let i = 0; i < pixels.length; i += 3) cells.push(classify(pixels[i], pixels[i + 1], pixels[i + 2]))
  const p = cells.filter((c) => c === 'P').length
  const a = cells.filter((c) => c === 'A').length
  const pct = p + a > 0 ? Math.round(p * 100 / (p + a)) : 0
  console.log(`f${n}: ${cells.join('')}  purple=${pct}%`)
}
```

**De output geeft het waarheidsbeeld dat image-view niet levert.** Je ziet niet alleen dat de bar van amber naar paars gaat, je ziet exact dat er op frame 13 een sprong naar 28% is, op frame 14 een piek naar 33%, op frame 27 een laagste punt van 12%, etc. Pas met deze data kun je terugrekenen welke CSS-transition, $effect-race, of JS-reset de oorzaak is.

**Wanneer gebruiken**:
- Een user meldt een bug in een animatie die jij visueel niet ziet.
- Je twijfelt of een progress-bar lineair vult of overshoot heeft.
- Je ziet een piek/dal/oscillatie en wilt weten hoeveel het is.
- Twee elementen animeren tegelijk en je wilt weten of ze synchroon lopen.

**Wanneer niet nodig**:
- Grove beweging (heel element verplaatst, opacity 0→1).
- Een verschil van 20%+ dat je met het oog ziet.

**Vuistregel**: als de user twee keer zegt "er zit nog een knipper/terugtrekking/jitter" en jij ziet het niet, ga van visueel inspecteren naar pixel-sampling. Image-view heeft sub-5% bewegingen gewoon niet in resolutie.

## Fundament

**Robin Williams (CRAP):** Contrast (maak verschil onmiskenbaar of maak het gelijk), Repetition (herhaal visuele keuzes voor samenhang), Alignment (alles moet visueel verbonden zijn met iets anders), Proximity (nabijheid impliceert relatie).

**Gestalt (Wertheimer, Koffka):** Het brein zoekt de eenvoudigste interpretatie (Pragnanz). Gelijke elementen worden als groep gezien (Similarity). Dit is waarom een 12-jarige spacing-problemen "ziet" en Claude niet: het brein doet het automatisch, Claude moet het bewust doen.

**Muller-Brockmann (Grid Systems):** Alle spacing-waarden afleiden van een gedeelde basis. Het grid is een discipline die willekeur voorkomt.

**Tufte:** Maximaliseer de data-ink ratio. Elk visueel element moet bijdragen aan begrip. **Tschichold:** Witruimte is een actief ontwerpelement, niet wat overblijft.

**Arnheim (Art and Visual Perception):** Visueel zwaartepunt telt meer dan pixel-midden. Optisch centrum ligt boven geometrisch centrum. Asymmetrische balans via visuele weging (massa, contrast, kleur) is levendiger dan strikte symmetrie.

**Apple HIG / Material Design / Lucide (icon grids):** Elk icoon heeft twee bounding boxes. Een outer canvas en een inner "live area". Primaire content blijft binnen de live area, secundaire content mag tot de outer, nooit daarbuiten. Material: 24x24 canvas, 20x20 live area, 2 dp padding rondom. Lucide: 24x24 canvas, 22x22 live area, stroke-width 2 centered (wat de feitelijke rand nog een halve stroke naar buiten duwt). Apple SF Symbols: inner icon-grid box plus outer bounding box. Een icoon dat de outer raakt voelt out-of-place.

**Bjango / Spiekermann (optical adjustments):** Mathematisch identieke vormen zijn optisch ongelijk. Cirkels moeten overshooten baseline en x-height. Scherpe punten van driehoeken moeten buiten de bounding box steken. Verticale lijnen moeten dikker lijken dan horizontale om gelijk te wegen. Het is geen illusie die gefixt moet worden, het is hoe ogen werken.

## Werkverdeling met art-director en impeccable

Eye-of-the-beholder is diagnostisch. Het kijkt naar wat er IS en vergelijkt dat met intentie. Twee zuster-skills zijn verantwoordelijk voor andere momenten in de keten.

**art-director** (zelfde plugin, sister-skill) werkt upstream. Voordat er CSS bestaat: definieer brand (wie zijn we), visuele taal (hoe klinken we visueel), en design-system-architectuur (hoe schaalt dit). Levert `brand.md`, `visual-language.md`, en een `design-system/` skeleton. Wanneer eye-of-the-beholder observeert dat een hue niet past of een spacing niet ritmeert, hoort de onderliggende standaard in art-director's artefacten te staan, niet in elke reviewer's hoofd.

**impeccable** (externe plugin) gebruikt de standaard tijdens het bouwen. Per feature. Bevat de normatieve regels in `reference/color-and-contrast.md`, `motion-design.md`, `typography.md`, `spatial-design.md`, en andere. Eye-of-the-beholder verwijst naar impeccable voor de regels; impeccable verwijst naar art-director's artefacten voor de concrete brand-keuzes binnen die regels.

De keten in tijd: art-director eenmalig (bij nieuw product, brand refresh, eerste DS-foundation), impeccable per feature tijdens bouwen, eye-of-the-beholder per wijziging achteraf om visueel te verifieren. Wanneer eye-of-the-beholder een probleem signaleert dat niet in een losse view zit maar systeembreed voorkomt (bijv. een ongecoordineerde spacing-schaal), is dat een signaal dat art-director werk onvolledig of ontbrekend is.

## Veelvoorkomende blinde vlekken

| Wat Claude doet | Wat er misgaat |
|-----------------|----------------|
| `padding: 0.6rem 0` schrijven | De 0 is nul ruimte links/rechts. Lees elke waarde. |
| Element buiten de hoofdcontainer plaatsen | Dat element erft geen padding. Het heeft eigen spacing nodig. |
| Naar het midden kijken, niet naar de randen | Het midden ziet er altijd goed uit. De fouten zitten aan de randen. |
| Alleen perimeter-padding meten, niet sibling-gaps | Container heeft 32px rondom, maar paragraaf raakt tabel eronder. Collapsed padding. Loop expliciet langs elk sibling-paar binnen de container. |
| `:host` / container padding doorgezogen door margin-collapse | Eerste kind-margin-top collapseert door parent-padding-top als de parent geen border/padding-tussen-ruimte heeft. Fix met `display: flow-root` of expliciete border-top. |
| "Past het?" als evaluatiecriterium | Fit is niet kwaliteit. Iets kan passen en er tegelijk lelijk uitzien. |
| Een fix doen en stoppen | Elke fix triggert een rescan van alle vier de randen. |
| CSS lezen als bewijs | CSS beschrijft intentie, niet resultaat. De screenshot is de waarheid. |
| Fontsizes verkleinen om te passen | Krimpen is altijd fout. Herstructureer de layout. |
| SVG-pad vult de viewBox tot de rand | Default `overflow: hidden` clipt stilletjes. Laat 1-2 eenheden marge, of vergroot de viewBox. |
| Stroke-width vergeten bij bounds-check | Centered stroke voegt `width/2` toe aan alle kanten. Een path tot y=16 met stroke=2 eindigt feitelijk op y=17. |
| Glyph mathematisch centreren | Optisch centrum ligt hoger. Duw 2-5% omhoog. |
| Ronde vorm gelijk maken aan vierkante | Cirkels moeten ~113% zijn om optisch gelijk te wegen. |
| Alleen de pagina-randen tracen | Trace is fractaal. Elke container met randen verdient een edge-trace: component, glyph, pad, pixel. |
| Tekst en icoon symmetrisch centreren in een pill | Font ascent > descent maakt digits optisch hoog. Align op cap-height center, niet bounding box. Micro-translate van 0.5-1px of cap-height line-height. |
| Opacity modifier als derde tekstkleur (`text-foo/50`) | Je hebt een missend tertiary-niveau, geen halve tekst. Definieer een expliciet token. |
| Palette-kleur in app-code (`text-red-500`) | Semantic bypass. Vervang door `text-danger` of vergelijkbaar. |
| Hardcoded hex in een component style block | Missing token. Definieer een nieuwe rol, of gebruik een bestaand token dat past. |
| "Dark mode ziet er wel ok uit" zonder math | Check de ratios. Surface delta onder 1.07x is onzichtbaar, text contrast onder 4.5 faalt AA. |
| Twee aangrenzende surfaces waar je geen verschil ziet | Het verschil IS er niet. Vergroot de luminance-delta tot minstens 1.07x. |
| Kleurwaarden voor licht zonder tegenwaarde voor donker | Beide modes zijn aparte ontwerpen. Gebruik `light-dark(L, D)` zodat ze naast elkaar leven. |
| Alleen rest-state screenshots bij animatie | De reis is de bug. Neem frames of gebruik de slow-mo truc om mid-animation te inspecteren. |
| Progress-animaties beoordelen op gewone screenshots | 5% verschillen in bar-fill zijn onzichtbaar op gewoon image-view. Sample pixels direct uit frames. Zie "Pixel-level animatie-sampling" sectie. |
| Content die verdwijnt vóór zijn container | Teleporting element. Delay `visibility: hidden` met `transition: visibility 0s linear var(--duration)` op de hidden-state. |
| Hardcoded ms/ease verspreid over componenten | Definieer `--duration-*` en `--ease-*` custom properties, gebruik overal. Anders drijven elementen bij eerste refactor uit elkaar. |
| `transition: all` | Animeert ook kleur, border, layout-props. Expliciet: `transform var(--dur), opacity var(--dur)`. |
| `will-change: width` | Anti-pattern per MDN. Width is een layout-property en krijgt geen GPU compositing. Gebruik alleen `will-change: transform` / `opacity`. |
| Inline `style:width` zonder `transition` regel | Snapt instant. Grep op `style:` in componenten om snapping elements op te sporen. |
| Cells die naar 0 collapseren ipv off-screen parken | Collapse forceert "van niets naar iets" sprongen. Park via visibility-hidden met behouden renderWidth. |

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

Na het bekijken van een reeks frames (animatie):

```
Observatie per frame (voor ik naar de CSS kijk):
- Frame 0 (start): nav toont 3 titels, content toont 3 cells, alles netjes in ritme.
- Frame 3 (mid): nav staat al op de nieuwe layout met 2 titels, content is halverwege.
  De nav-titels zijn gesnapt, de cells animeren nog.
- Frame 6 (eind): nav en content beide in eindpositie.
- Vreemde eend: de nav loopt niet in ritme met de content. Ze eindigen samen maar
  beginnen niet samen.
- Verdwijnende content: in frame 3 is de inhoud van de wegglijdende cell al hidden
  terwijl zijn container nog beweegt. Teleporting element.

Diagnose (na CSS check):
- .nav-title heeft inline style:width maar geen `transition` regel in de CSS.
- .cell-collapsed zet visibility: hidden instant zonder delay.

Fix:
- .nav-title krijgt transition: width var(--duration) var(--ease).
- .cell-collapsed krijgt transition: visibility 0s linear var(--duration), zodat
  de visibility pas flipt nadat de beweging klaar is.
```
