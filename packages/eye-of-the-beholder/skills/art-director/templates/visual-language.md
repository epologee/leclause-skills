# Visual language: [Product naam]

Per as: wat heeft dit merk gekozen, waarom, met welke bron? Elk blok heeft vier velden. Vul in, vervang, verwijder de instructie-zinnen zodra de inhoud staat.

## Type-as-voice

**Principe**: *Een korte regel over wat type hier doet. Bijv. "Neutraal humanist sans voor UI, licht geometrische display voor koppen, mono voor code."*

**Gekozen**:
- Display: [family, gewicht, bron]
- Body: [family, gewicht, bron]
- Mono: [family, gewicht, bron]

**Rationale**: *Waarom deze pairing? Koppel elk aan een brand-attribuut uit `brand.md`. Niet "elegant = serif". Wel "we kozen Inter omdat het een neutrale humanist sans is die schaalt zonder karakterverlies tussen UI en display, en omdat de brand 'helder maar niet clever' is willen we een type dat zijn eigen stem niet te sterk oplegt."*

**Referentie**: [Werk + hoofdstuk, bijv. Lupton *Thinking with Type*, H2 "Letter".]

---

## Color-as-mood

**Principe**: *Een korte regel over wat kleur hier doet. Bijv. "60-30-10 met warme neutralen + een diepe accent-hue voor brand-momenten."*

**Gekozen** (in OKLCH, perceptueel uniform):
- Brand hue: `oklch(L C H)` [fysieke referentie, bijv. "oude bibliotheekrug, ruwe texture"]
- Secundair accent: `oklch(L C H)` [referentie]
- Neutraal-scale: [waardes voor surface-1 tot surface-5, eventueel via `light-dark()`]
- Status groen: `oklch(L C H)`
- Status geel: `oklch(L C H)`
- Status rood: `oklch(L C H)`

**Rationale**: *Waarom deze palette? Fysieke referenties, niet emotionele labels. Hoe stuurt het de brand-attributen?*

**Referentie**: [bijv. Albers *Interaction of Color* voor hoe kleuren in context verschuiven; Adams *Designer's Dictionary of Color* voor de specifieke hue.]

---

## Form-as-attitude

**Principe**: *Een korte regel. Bijv. "Zacht maar disciplined: 8 px radius, 1 px borders, geen shadows."*

**Gekozen**:
- Corner radius: [waarde + eventueel scale `--radius-sm`, `--radius-md`, `--radius-lg`]
- Border weight: [waarde + "default" / "emphatic"]
- Surface depth: [aantal niveaus + hun luminance-delta]
- Shadow language: [flat / soft / hard + specs per niveau]

**Rationale**: *Hoe drukt deze geometrie de brand-attributen uit?*

**Referentie**: [bijv. Wathan & Schoger *Refactoring UI* H"Depth" voor shadow-beslissingen.]

---

## Motion-as-tempo

**Principe**: *Een korte regel. Bijv. "Unhurried en zorgvuldig: 280 ms met expo-out voor de meeste state changes, 120 ms voor direct feedback zoals button-press."*

**Gekozen**:
- `--duration-instant`: [waarde]
- `--duration-fast`: [waarde]
- `--duration-base`: [waarde]
- `--duration-slow`: [waarde]
- `--ease-entrance`: [cubic-bezier of named]
- `--ease-exit`: [cubic-bezier of named]
- `--ease-standard`: [cubic-bezier of named]

**Rationale**: *Welk tempo spreekt de brand-persoonlijkheid uit? Snelle ease-out = efficient, langere expo = overwogen, micro-bounce = speels.*

**Referentie**: [bijv. impeccable's `reference/motion-design.md` voor normatieve regels, Walter *Designing for Emotion* voor persoonlijkheid-koppeling.]

---

## Photography en illustration tone

**Principe**: *Een korte regel. Bijv. "Editorial product photography op neutrale achtergrond, geen stock, illustraties alleen als wayfinding."*

**Gekozen**:
- Photography register: [editorial / product / documentair / stock] + [met / zonder mensen]
- Kleur-behandeling: [volledig gekleurd / monochroom / duotone]
- Illustration register: [geometrisch / organisch / hand / flat] + [mono / gekleurd]
- Mix-and-match regel: [waar photography, waar illustration, nooit samen / op welke manier samen]

**Rationale**: *Waarom dit register? Hoe past het bij de brand-attributen en hoe onderscheidt het zich van concurrenten uit de competitive scan?*

**Referentie**: [bijv. Wheeler *Designing Brand Identity* fase 3 designing identity voor touchpoint-consistentie.]

---

## Decision log entries (toekomstige wijzigingen)

*Bij elke wijziging in dit document: voeg een entry toe onderaan met datum, auteur, wat veranderde, waarom.*

| Datum | Auteur | As | Wijziging | Waarom |
|-------|--------|----|-----------|--------|
| [YYYY-MM-DD] | [naam/rol] | [Type/Color/Form/Motion/Photo] | [kort] | [brand-rationale] |
