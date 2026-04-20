# Design system governance: [Product naam]

Wie mag wat wijzigen, wanneer, via welk proces. Zonder governance wordt een design system binnen een jaar een kerkhof van half-geadopteerde tokens en duplicate componenten.

## Contribution model

### Nieuw component voorstellen

Via een PR naar deze repo met:

- **Design rationale**: waarom bestaat dit component? Wat lost het op dat een bestaand component niet kan?
- **Alternatieven overwogen**: welke bestaande componenten heb je overwogen en waarom vielen ze af?
- **Component contract** (zie `components/_example.md`): API, states, variants, slots, a11y, do/don't.
- **Visual**: mockup of screenshot in drie states (rest / hover of focus / disabled).
- **A11y checklist**: rol, keyboard support, screen-reader-namen, contrast-ratio's gecheckt tegen `reference/color-and-contrast.md` (WCAG AA).

### Bestaand component wijzigen

- **Impact assessment**: welke andere componenten en pagina's gebruiken dit?
- **Breaking vs additive**: is deze wijziging breaking (prop verwijderd, default aangepast, visueel gedrag veranderd) of additive (nieuwe prop, nieuwe variant)?
- **Migratiepad bij breaking**: voor hoe lang blijft de oude API beschikbaar? Wat is het communicatiepad?

### Nieuw token toevoegen

- **Primitive**: mag ieder teamlid per PR.
- **Semantic**: review door design owner. Waarom is de bestaande semantic laag niet voldoende?
- **Component**: alleen wanneer de semantic laag geen passend vocabulaire heeft. Als je vaak component tokens toevoegt, is de semantic laag incompleet; bespreek eerst met design owner.

## Review

- **Design owner**: [rol of persoon].
- **Technical owner**: [rol of persoon].
- Elke design-system PR krijgt beide reviewers. Approve van één is niet voldoende; beide moeten approven.
- **SLA voor review**: [bijv. binnen 2 werkdagen na aanvraag].
- **Blocking vs non-blocking feedback**: expliciet in elke comment. Blocking = merge pas na fix. Non-blocking = follow-up PR mag.

## Semver

Design system volgt semantic versioning, op zowel tokens als componenten:

- **Major**: breaking change. Token hernoemd, component-API gewijzigd, visueel gedrag fundamenteel anders.
- **Minor**: additive. Nieuw token, nieuwe variant, nieuwe component. Bestaand gedrag onveranderd.
- **Patch**: bugfix, visuele verfijning zonder gedragsverandering, documentatie. Een brand-hue die 5 graden opschuift in OKLCH is patch als het perceptueel geen breuk voelt; major als het merk visueel anders leest.

## Deprecation

Een token of component wordt nooit stilletjes verwijderd. Proces:

1. **Markeer als deprecated**: JSDoc of CSS comment `/* @deprecated: use --color-accent instead, removed in v3.0.0 */`.
2. **Console warning of linter rule** op gebruik in de codebase.
3. **Communicatie**: changelog entry, bericht in gedeelde kanalen, entry in design-system-roadmap.
4. **Minimum window**: [bijv. 2 minor releases of 6 kalendermaanden], afhankelijk van product-releasecadans.
5. **Verwijdering**: pas na de window. Bij verwijdering: changelog entry als breaking change + major bump.

## Review cadans

- **Token audit**: [bijv. elke drie maanden]. Zijn er nog primitives in application code? Zijn er semantic tokens die niet gebruikt worden?
- **Component audit**: [bijv. elke zes maanden]. Zijn er duplicate componenten ontstaan (twee soort-gelijke buttons, drie soort-gelijke cards)?
- **Governance audit**: [bijv. jaarlijks]. Werkt dit proces nog voor het team?

---

## Referenties gebruikt

- Kholmatova, *Design Systems* (Smashing): semver voor tokens, contribution model.
- DesignBetter, *Design Systems Handbook*: team-organisatie en governance cadans.
- Curtis, Eightshapes: DS team structures + rollen.
