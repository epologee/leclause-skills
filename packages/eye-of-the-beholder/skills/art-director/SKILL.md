---
name: art-director
user-invocable: true
description: Use when starting a new product, brand refresh, or design-system foundation, before UI work begins. Triggers on explicit requests for "art direction", "brand work", "visual language", or "design system architecture". Also use when a project has been building features without a documented brand, visual language, or token taxonomy, and the choices have become reflex-driven. NOT for small UI tweaks, per-component review, single-screen layout fixes, or anti-AI-slop checking: those are eye-of-the-beholder (diagnose) and impeccable (apply standard). Art direction works upstream of both: it captures who the product is, how it speaks visually, and how its system scales, BEFORE CSS exists.
---

# Art Director

## Het echte probleem

Claude start een product of feature en kiest visuele eigenschappen op gevoel. Een hue uit de Tailwind default scale, een radius die ergens tussen 4 en 12 px zit, een ease-curve die overgenomen is uit een eerdere repo. Dat voelt productief, maar er is geen brand om die keuzes tegen te ijken. "Past dit bij ons?" is niet beantwoordbaar als "ons" nog nooit gedefinieerd is.

Hetzelfde geldt voor teams met een brand: als die brand in de hoofden van drie mensen zit en niet op papier, vindt elke nieuwe developer een iets ander paletje uit. Na een jaar heeft het product visuele slijtage door accumulatie van losse keuzes. Op code-niveau heet dat technische schuld; op brand-niveau heet het geen naam, maar het eruit trekken kost net zo veel.

**Art-director werkt vooraf.** De output is geen UI, maar een set artefacten die toekomstig UI-werk concreter en minder reflex-gestuurd maken. Brand brief, visuele taal, design-system architectuur. Daarna kan impeccable tijdens de bouw verwijzen naar die artefacten ("de brand hue is deze, niet die") in plaats van per feature opnieuw te kiezen. En eye-of-the-beholder kan achteraf verifieren tegen een bestaand ritme in plaats van een losse intuitie.

## Positionering

Art-director zit tussen discovery en productie. Drie skills, drie momenten:

- **art-director**, definieer standaard. Vooraf, eenmalig per project of per brand refresh. Levert `brand.md`, `visual-language.md`, en een `design-system/` skeleton.
- **impeccable**, gebruik standaard tijdens het bouwen. Per feature. Verwijst naar art-director's artefacten voor concrete keuzes ("pak de hue uit `visual-language.md`", niet "kies een warme accentkleur").
- **eye-of-the-beholder**, verifieer na elke wijziging. Diagnostisch. Screenshot, observeer, vergelijk met intentie. Verwijst naar impeccable voor regels en naar art-director voor brand-context.

De drie zijn niet inwisselbaar. Een design system zonder brand is een catalogus zonder stem. Brand zonder design system is een poster zonder uitvoering. Een UI zonder eye-of-the-beholder is een statisch correct plaatje dat onder beweging of in een ander scherm kapot gaat. Elke skill heeft zijn eigen moment.

## Wanneer

Art-director mag NIET activeren bij elk stukje design-werk. Dat was de fout die eye-of-the-beholder niet wilde maken en die art-director ook niet wil maken. Actieve triage:

**Wel activeren:**

- Nieuw product of nieuwe productlijn die nog geen brand heeft.
- Brand refresh van een bestaand product (oude brand vervangen, niet aanvullen).
- Eerste design-system-foundation leggen: de allereerste tokens, de allereerste atomaire componenten, het eerste governance-model.
- User vraagt expliciet om "art direction", "brand work", "visual language", of "design system architecture".

**Niet activeren:**

- Kleine UI-tweak (spacing, kleur van een knop, nieuwe view in een bestaande flow). Dat is impeccable + eye-of-the-beholder.
- Per-component visuele review. Dat is eye-of-the-beholder.
- Anti-AI-slop check op een feature. Dat is impeccable.
- Single-screen layout-fix. Dat is eye-of-the-beholder.
- "Maak de kleuren wat mooier" zonder brand-context. Stuur door naar impeccable's `colorize` of `bolder` sub-skill.

Als de vraag "bouw dit schermpje" is, is art-director het foute antwoord. Als de vraag "wat is de visuele identiteit van dit product" is, dan wel.

## Module 1: Brand identity discovery

Doel: vastleggen wie het product is voordat je tekent. Vijf fases, afgeleid van Alina Wheeler's vijf-fase model in *Designing Brand Identity* (Wiley, 6e editie). Volledige citatie in `references.md`.

### 1.1 Conducting research

Voor je over visueel materiaal praat: leer de situatie kennen. Drie richtingen.

- **Stakeholder interviews.** Wie heeft belang bij hoe dit product eruit ziet? Oprichters, gebruikers, investeerders, bestaande klanten, team. Drie tot vijf korte gesprekken (30-45 min). Vraag niet naar kleuren of fonts. Vraag naar: wat doet het product fundamenteel, voor wie, waarom nu? Wat zou het product nooit mogen worden? Welke concurrenten wekken irritatie en waarom?
- **Competitive scan.** Lijst direct-concurrenten + aangrenzende categorieen. Voor elk: naam, visuele register (minimaal / maximalistisch, professioneel / casual, warm / koel), wat werkt wel, wat werkt niet. Doel is niet imiteren maar positionering. Je wilt weten waar je zelf gaat staan ten opzichte van dit landschap.
- **Audit van bestaand materiaal.** Als het product al bestaat: screenshots van elke view, printouts waar van toepassing, marketing assets. Lijst inconsistenties. Wat zijn de vijf meest voorkomende kleuren in het huidige product? Komen die overeen met de intentie of zijn ze drift?

Output: een rapport van 1-2 pagina's per stakeholder-groep + 1 pagina competitive scan + 1 pagina audit-bevindingen.

### 1.2 Clarifying strategy

Uit de research rolt strategie. Wheeler's brand brief destilleert tot drie artefacten.

- **Positionering.** In één zin, niet een alinea. Formule: "Voor \[doelgroep\] is \[product\] de \[categorie\] die \[waarde\]." Niet om op een homepage te plakken, maar om intern aan te toetsen.
- **Persoonlijkheid.** Kies DRIE attributen + DRIE anti-attributen. "Helder" is een attribuut, "niet clever" is een anti-attribuut. Anti-attributen voorkomen dat attributen zo breed worden dat ze betekenisloos zijn. "Vriendelijk" kan voor een chatbot en voor een funeral home; "vriendelijk maar niet vrolijk" is scherper.
- **Promise.** Wat belooft dit merk aan zijn gebruiker? Niet feature, maar uitkomst. Neumeier's *The Brand Gap* noemt dit de "onion": functional (wat), emotional (hoe voelt het), self-expressive (wat zegt het over mij als ik dit gebruik).

Output artefact: `brand.md` met secties Strategy / Positioning / Personality / Anti-personality / Voice / Touchpoints / Governance. Template in `templates/brand.md`.

### 1.3 Designing identity

Nu pas komt visueel materiaal. Elk primitive vertaalt brand-strategie naar een visuele keuze.

- **Logo.** Wordmark, symbol, of combo. David Airey's *Logo Design Love* (zie referenties) geeft het decision-framework: past het in een favicon? Kan het monochroom? Werkt het op een t-shirt? Niet elk product heeft een logo nodig; soms is een wordmark genoeg.
- **Type.** Zie Module 2 voor de details. Hier: kies een pairing die brand-attributen belichaamt.
- **Color.** Zie Module 2. Hier: kies een brand hue en secundaire palette.
- **Voice.** Hoe klinken micro-copy, error messages, CTAs? Een merk dat "helder maar niet clever" is, schrijft geen puns in foutmeldingen. Een merk dat "warm en rustig" is, gebruikt geen uitroeptekens. Schrijf 5-10 voorbeelden van product-copy in de gekozen stem: een success toast, een 404-pagina, een onboarding hint, een email subject line. Die voorbeelden worden de ijkpunten.

### 1.4 Creating touchpoints

Per medium waar het merk verschijnt: hoe gedraagt de identiteit zich daar? Web, mobiel, print, social, email, events, product packaging. Niet elk product heeft ze allemaal. Maar voor elk dat het product WEL gebruikt:

- Wat is de primaire visuele gedraging? (Bijv. op web: brand hue als accent op neutrale achtergrond. In email: een logo-mark en neutrale body.)
- Wat zijn de anti-patronen? (Bijv. geen kleurverlopen op de logo, geen photo filters op product screenshots.)
- Wie beheert dit touchpoint? (Wie mag dit wijzigen, wie mag alleen gebruiken?)

### 1.5 Managing assets

Governance. Wie mag wat wijzigen en wanneer. Drie vragen:

- **Contribution model.** Kan iedereen in het team een nieuwe component voorstellen? Een nieuwe kleur-token toevoegen? Of loopt dat langs een ontwerp-review?
- **Versioning.** Wanneer is een wijziging breaking vs additive? Nathan Curtis (zie referenties) heeft uitgebreid geschreven over semver voor design tokens: een token-rename is breaking, een token-toevoeging is additive, een waarde-tweak binnen perceptuele tolerantie is patch.
- **Deprecation.** Hoe loopt een oude token of component af? Stilletjes verwijderen is een breaking change zonder waarschuwing. Een deprecation-window (6 maanden, 12 maanden) met console warnings op gebruik is de standaard.

## Module 2: Visual language translation

Doel: van brand-attributen naar visuele vocabulaire. Vijf assen. Per as: kies, documenteer het principe, citeer de bron, leg vast in `visual-language.md`.

### 2.1 Type-as-voice

Type is de stem van een merk op pagina. Een pairing bestaat uit display (koppen, hero) en body (lopende tekst, UI). Soms een derde voor mono (code, data).

- **Niet "elegant = serif".** De reflex ("serif voelt klassiek, sans-serif voelt modern") is te grof. Een moderne didone zoals GT Super voelt anders dan een klassieke Garamond, allebei serifs. Een geometric sans zoals Futura voelt kouder dan een humanist sans zoals Inter. Kies op basis van brand-persoonlijkheid, niet op basis van de grofste classificatie.
- **Documenteer het waarom.** "We kiezen Inter omdat het een neutrale humanist sans is die goed schaalt tussen UI (12-14px) en display (48-72px) zonder karakterverlies, en omdat de brand 'helder maar niet clever' is, willen we een type dat zijn eigen stem niet te sterk oplegt." Dat onderscheidt een typekeuze van een smaak-voorkeur.
- **Referenties.** Ellen Lupton's *Thinking with Type* (2e ed.) is de canonieke intro. Jim Williams' *Type Matters!* geeft het pragmatische micro-typografie werkboek. Matthew Butterick's practicaltypography.com is online en pay-what-you-want, vooral sterk voor body-type. Klim Foundry case studies laten zien hoe een type-ontwerper voor specifieke merken werkt. Voor volledige citaties zie `references.md`.

### 2.2 Color-as-mood

Kleur drukt stemming uit. Kleine nuances dragen ver.

- **Kies in OKLCH, niet in HSL.** OKLCH is perceptueel uniform: twee kleuren met dezelfde L-waarde voelen even licht, wat bij HSL niet geldt. Voor details, zie impeccable's `reference/color-and-contrast.md`. Hier gaat het erom dat je een brand hue kiest die perceptueel stabiel is over licht en donker.
- **Documenteer fysieke referentie, niet emotionele labels.** "De brand hue is een diepe blauwgroen geinspireerd op oude bibliotheekruggen (ruwe texture, licht verweerd)" is sterker dan "een kalme blauwgroen". De eerste geeft een verifieerbaar mentaal beeld waar je tegen kunt toetsen bij een volgende keuze. De tweede is een emotioneel label dat bij elke volgende reviewer iets anders betekent.
- **60-30-10 als startpunt.** Een vuistregel uit interieurontwerp die ook op schermkleur werkt: 60% neutraal, 30% secundair, 10% brand accent. Niet een wet, wel een eerste check op hoeveel van je scherm je aan het merk wilt opdragen.
- **Secundair palette.** 2-4 kleuren die ondersteunend zijn. Eén status-groen, één warning-geel, één danger-rood, eventueel één extra accent. Kies ze in relatie tot de brand hue, niet los.
- **Referenties.** Josef Albers' *Interaction of Color* (Yale, 50e anniversary ed.) voor hoe kleur in context verandert. Sean Adams' *The Designer's Dictionary of Color* voor per-kleur culturele context. Aarron Walter's *Designing for Emotion* voor hoe kleur met brand-persoonlijkheid samenhangt. Volledige citaties in `references.md`.

### 2.3 Form-as-attitude

Geometrie drukt houding uit. Corner radius, border weight, surface depth, shadow language.

- **Corner radius als spectrum.** 0 px is brutalist / industrieel / serieus. 2-4 px is geometrisch / zakelijk. 8-16 px is zacht / vriendelijk. Volledig pill (`9999px`) is speels / vriendelijk / tech-consumer. Kies een waarde die bij de persoonlijkheid past en documenteer dat in een regel: "Onze corner radius is 8 px omdat we zacht en benaderbaar willen zijn zonder kinderachtig te voelen."
- **Border weight.** 1 px is default-web. 2-3 px voelt gewichtiger, soms brutalist. Geen border (alleen surface-delta) is rustiger.
- **Surface depth.** Hoeveel niveaus heeft je interface? Background, canvas, panel, dialog, popover = 5 niveaus. Elk met zijn eigen luminance. Zie eye-of-the-beholder voor de 1.07x delta-regel om die niveaus perceptueel te scheiden.
- **Shadow language.** Geen shadows (flat), zachte shadows (soft material), harde shadows (neubrutalism). Kies een stijl en houdt die consistent. Twee shadow-stijlen in een interface is altijd een bug.

### 2.4 Motion-as-tempo

Tijd is de vierde ontwerpdimensie. Hoe snel iets beweegt vertelt over temperament.

- **Duration als brand-expressie.** Brand "unhurried, zorgvuldig" = langere durations (250-400 ms) met expo-out curves (ease die vroeg snel en laat zacht eindigt). Brand "snappy, efficient" = korte durations (120-180 ms) met standaard ease-out. Brand "speels" = micro-bounce easing op state changes.
- **Ease-vocabulaire.** Definieer 3-5 named eases: `--ease-entrance`, `--ease-exit`, `--ease-gentle`, `--ease-snappy`. Voor de normatieve details over welke eases wanneer te gebruiken, zie impeccable's `reference/motion-design.md`.
- **Referenties.** Zie de design-motion-principles documentatie (Emil Kowalski, Jakub Krehel, Jhey Tompkins) voor per-designer motion vocabularies. Walter's *Designing for Emotion* voor hoe motion met persoonlijkheid samenhangt.

### 2.5 Photography en illustration tone

Indien het product visuele content heeft: welke registers mag die content aannemen?

- **Photography.** Editorial / product / documentair / stock. Met / zonder mensen. Gekleurd / monochroom. Documenteer dat "wij gebruiken editorial-style product photography op neutrale achtergronden, nooit stock-photos van mensen in kantoren" is duidelijk genoeg om een PR te rejecten op.
- **Illustration.** Geometrisch / organisch / hand-gedraaid / flat. Mono-line / gekleurd. Als je illustrations gebruikt, zijn ze decoratief of narratief?
- **Mix-and-match verbod.** De combinatie van photography en illustration in een product is riskant; veel merken kiezen één register. Als beide: definieer waar elk wordt ingezet en waarom.

## Module 3: Design system architecture

Doel: van losse tokens en componenten naar een systeem dat schaalt zonder bij elke nieuwe developer opnieuw gedacht te moeten worden. Vijf elementen.

### 3.1 Token taxonomie in drie lagen (Curtis model)

Nathan Curtis's drie-laags model is de standaard voor token-design. Zie zijn Eightshapes essays op medium.com/eightshapes-llc voor de volledige uitleg.

```
primitive:  --blue-500: oklch(0.62 0.18 260);
semantic:   --color-accent: var(--blue-500);
component:  --button-bg: var(--color-accent);
```

- **Primitive tokens** zijn de fysieke kleurenpalet, fysieke spacing-schaal, fysieke font-scale. Ze zijn betekenisloos ("blue-500" zegt niks over wat het is in je product). Ze bestaan zodat een semantic laag ergens naar kan verwijzen.
- **Semantic tokens** geven rol. `--color-accent`, `--color-danger`, `--color-text-primary`, `--color-surface-1`. Applicatiecode praat ALLEEN tegen deze laag. Als de brand hue verandert, wijzig je één alias: `--color-accent: var(--red-500)` in plaats van `var(--blue-500)`. Alle componenten volgen automatisch.
- **Component tokens** zijn een derde, optionele laag voor componenten met eigen variatiebehoefte. `--button-primary-bg: var(--color-accent)` laat de button zijn eigen token definieren zonder de semantic laag te vervuilen.

Twee anti-patronen. Eerst: applicatie-code die rechtstreeks naar primitives verwijst (`background: var(--blue-500)` in een `.button` selector). Dat is een bypass van de semantic laag en maakt brand-wijzigingen duur. Tweede: semantic names die eigenlijk primitives zijn vermomd (`--color-blue-primary` is geen semantic naam, `--color-accent` wel).

### 3.2 Component taxonomy (Frost atomic)

Brad Frost's *Atomic Design* (Macmillan, 2016, gratis online op atomicdesign.bradfrost.com) geeft de vijf-laags structuur:

- **Atoms.** De kleinste zinvolle unit: button, input, label, icon, badge.
- **Molecules.** Atoms gecombineerd tot kleine functional units: search-field (input + button + icon), form-row (label + input + help text).
- **Organisms.** Molecules samen in herkenbare secties: page-header (logo + nav + search), card-grid, comment-thread.
- **Templates.** Layout-structuren zonder content: "a two-column settings page."
- **Pages.** Templates met echte content.

Niet elke component valt schoon in één laag. Twijfel is OK. Wat telt: dat er een laag IS. Een design system zonder taxonomie heeft 80 components in een flat list die niemand kan terugvinden.

### 3.3 Component contract

Voor elk component: wat belooft het? Document dat per component.

- **API.** Welke props / slots / parameters? Types en defaults.
- **States.** Hover, focus-visible, active, disabled, loading, error. Elk expliciet.
- **Variants.** Primary / secondary / destructive / ghost. Elk met een brand-rationale: waarom bestaat deze variant en wanneer gebruik je hem?
- **Slots.** Kan de component children accepteren? Welke? Met welke beperkingen?
- **A11y requirements.** Rol, keyboard support, screen-reader-namen, contrast-ratio-minima. Voor de normatieve contrast-ratios zie impeccable's `reference/color-and-contrast.md`.
- **Do / don't.** Twee korte lijstjes met gebruiks-voorbeelden. Niet alle combinaties beschrijven, alleen de meest voorkomende fouten voorkomen.

Template: `templates/design-system/components/_example.md`.

### 3.4 Governance

Wie mag wat wijzigen en wanneer. Al aangeraakt in Module 1.5. Hier specifiek voor het design system.

- **Contribution model.** Een nieuwe component voorstellen: via een PR met een design-rationale en een a11y-checklist. Een bestaande component wijzigen: via een PR met impact-assessment (welke andere components gebruiken dit?).
- **Review criterium.** Eén design owner leest elke design-system PR. Geen technische reviewers-only. Code is niet het enige review-gebied.
- **Semver voor tokens en components.** Een token hernoemen = major. Een nieuw token toevoegen = minor. Een token-waarde aanpassen (brand hue schuift 5 graden in OKLCH) = patch, tenzij de verschuiving zichtbaar genoeg is om als breaking te voelen. Dan is het major.
- **Deprecation-window.** Minimum 2 minor releases of 6 kalendermaanden tussen "marked deprecated" en "verwijderd". Console warnings of linter warnings op gebruik van deprecated tokens.

### 3.5 Living docs

Een design system dat alleen in code leeft, kan niemand ontdekken. Levende documentatie:

- **Showcase-route.** Een `/design-system/` route in het product zelf, of een aparte Storybook / Histoire instance. Per component: een voorbeeld, een state-matrix (elke state zichtbaar), en de do/don't uit de component contract.
- **Token reference.** Een pagina die alle semantic tokens zichtbaar maakt in light + dark. Niet alleen kleurwaarden, ook spacing-schaal, type-schaal, radius-waarden.
- **Governance page.** De contributie-regels uit 3.4, toegankelijk voor iedereen die een PR overweegt.

Referenties: Yesenia Perez-Cruz's *Expressive Design Systems* voor hoe je een systeem expressief maakt in plaats van steriel. DesignBetter's *Design Systems Handbook* (gratis op designbetter.co/design-systems-handbook) voor team-organisatie. Adam Wathan en Steve Schoger's *Refactoring UI* (self-published) voor concrete tactical rules. Volledige citaties in `references.md`.

Publieke referentie-systemen om te leren hoe anderen het oplossen:

- **Polaris** (Shopify): polaris.shopify.com
- **Carbon** (IBM): carbondesignsystem.com
- **Primer** (GitHub): primer.style
- **Material 3** (Google): m3.material.io
- **IBM Design Language**: ibm.com/design/language
- **Atlassian Design System**: atlassian.design

Niet om te kopieren, wel om patronen en taxonomieen te zien.

## Werkverdeling met eye-of-the-beholder en impeccable

De drie skills zijn een keten. Volgorde in de projectlevensduur:

- **art-director** (eenmalig, upstream). Levert `brand.md`, `visual-language.md`, en `design-system/` skeleton. Na deze stap bestaat "ons merk" op schrift.
- **impeccable** (per feature, tijdens bouwen). Past de standaard toe. Verwijst terug naar art-director's artefacten voor concrete keuzes ("uit `visual-language.md`: hue is `oklch(0.62 0.18 260)`"). Voor de normatieve rules (contrast-ratios, transform/opacity-only, spacing-schaal) heeft impeccable zijn eigen reference-files.
- **eye-of-the-beholder** (per wijziging, achteraf). Verifieert visueel. Screenshot, observeer, vergelijk met intentie. Verwijst naar impeccable voor regels en naar art-director voor brand-context. Past observatie-vragen toe die geen van beide andere skills stelt ("kun je secundaire tekst lezen zonder te turen?").

Wat NIET art-director's terrein is: implementatie-CSS (impeccable + eye-of-the-beholder), per-component visuele review (eye-of-the-beholder), anti-AI-slop checklists (impeccable), single-screen layout fixes (eye-of-the-beholder).

## Output artefacten

Drie files, één directory. Templates leven in `templates/`.

- `brand.md`: strategy, personality, anti-personality, voice, touchpoints, governance.
- `visual-language.md`: per-as decision log (type, color, form, motion, photo/illo) met principle + chosen value + rationale + referentie.
- `design-system/tokens.md`: 3-laags Curtis model (primitive, semantic, component) met concrete waarden in OKLCH en andere units.
- `design-system/components/<name>.md`: per component contract. Template in `_example.md`.
- `design-system/governance.md`: contribution, review, semver, deprecation.

Gebruik de templates uit `templates/` als startpunt. Iteraties zijn normaal; een brand-document uit ronde 1 is bijna nooit het document uit ronde 3.

## Referenties

Zie `references.md` voor de volledige lijst van standaardwerken met ISBN, URL, en een eenregelige samenvatting per bron.
