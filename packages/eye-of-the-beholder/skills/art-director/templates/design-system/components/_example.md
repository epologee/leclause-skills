# Component: [Naam]

Kopieer dit bestand per nieuw component naar `components/<name>.md`. Vul elke sectie volledig in. Als een sectie niet van toepassing is, schrijf "N.v.t." met een korte onderbouwing, laat de sectie niet weg. Compleetheid is de helft van de reden dat dit document bestaat.

## Doel

*Eén tot twee zinnen. Wat lost dit component op, en voor welke gebruiker? Welk alternatief is niet goed genoeg en waarom?*

## API

### Props

| Prop | Type | Default | Required | Beschrijving |
|------|------|---------|:--------:|--------------|
| `variant` | `"primary" \| "secondary" \| "danger"` | `"primary"` |  | Welke variant; zie Variants sectie. |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` |  | Visueel formaat. |
| `disabled` | `boolean` | `false` |  | Interactie uit. |
| `loading` | `boolean` | `false` |  | Laadstate; pairt met aria-busy. |
| `leadingIcon` | `ReactNode` | | | Icoon voor de label. |
| `trailingIcon` | `ReactNode` | | | Icoon na de label. |
| `onClick` | `(e: MouseEvent) => void` | | | Handler. |

### Slots

*Kan dit component children accepteren? Zo ja, welke? Met welke beperkingen? Voorbeeld:*

- `children`: de label (tekst of ReactNode). Maximale lengte 40 tekens; langere labels falen in mobile layout.

## States

Elke state expliciet documenteren. Per state: visuele beschrijving, a11y-annotaties.

- **Rest**: default, geen interactie.
- **Hover**: cursor boven, geen klik. Visueel: [bijv. background shift via `--button-bg-primary-hover`].
- **Focus-visible**: keyboard focus. Visueel: [bijv. 2 px outline in `--color-accent`]. Screen reader: aria-label van `aria-describedby` gekoppeld waar nodig.
- **Active**: ingedrukt. Visueel: [bijv. 1 px translate-y voor depth-feedback].
- **Disabled**: uitgeschakeld. Visueel: [bijv. 40% opacity op label, cursor not-allowed]. A11y: `aria-disabled="true"`, NIET `disabled` attribute (anders wordt focus overgeslagen en mist de gebruiker context).
- **Loading**: in progress. Visueel: [bijv. spinner vervangt leading-icon, label blijft staan]. A11y: `aria-busy="true"`.
- **Error** (indien van toepassing): validatie gefaald. Visueel en a11y specs.

## Variants

Elke variant: wanneer gebruik je deze, met welke brand-rationale?

- **Primary**: de hoofdactie op de view. Eén per view. Brand-rationale: [bijv. "dit is waar we de gebruiker naartoe willen, dus visueel dominant"].
- **Secondary**: alternatieve actie. Meerdere toegestaan. Brand-rationale: [bijv. "subsidiair, neutrale surface zonder brand-accent"].
- **Danger**: destructieve actie. Gebruik spaarzaam. Brand-rationale: [bijv. "gebruikt status-danger kleur om de onomkeerbaarheid te signaleren"].

## A11y

- **Role**: [bijv. button (native) of role="button" indien non-button element].
- **Keyboard support**: Space en Enter activeren, Tab voegt toe aan tab-order, Shift+Tab gaat terug. Disabled skipt Tab niet als `aria-disabled`.
- **Screen reader name**: via children tekst, of `aria-label` wanneer alleen icoon.
- **Contrast ratios** (per variant, per state, tegen gebruikelijke achtergrond): minimaal WCAG AA (4.5:1 voor body text, 3:1 voor UI boundaries). Gecheckt tegen impeccable's `reference/color-and-contrast.md`.
- **Reduced motion**: respecteert `prefers-reduced-motion: reduce`; animaties weg of instant.
- **Minimum touch target**: 44x44 px op mobiel.

## Do

- Gebruik Primary voor exact één hoofdactie per view.
- Combineer leading-icon met een duidelijk label; icon-only buttons vereisen `aria-label`.
- Gebruik Loading state bij acties met latency > 300 ms.

## Don't

- Gebruik Danger voor niet-destructieve acties, ook niet "om op te vallen".
- Zet meer dan 3 buttons naast elkaar; dat is een menu, geen button-rij.
- Gebruik Primary + Secondary + Danger tegelijk in hetzelfde frame; kies hoogstens twee.

## Visuele voorbeelden

*Link of screenshot naar de showcase-route + een state-matrix (alle states als rij).*

![State matrix](../../../tmp/button-states.png)

---

## Referenties gebruikt

- Frost, *Atomic Design*: button als atoom + combinatie-regels.
- Kholmatova, *Design Systems*: states als onderdeel van component contract.
- impeccable's `reference/color-and-contrast.md`: AA/AAA thresholds.
- impeccable's `reference/interaction-design.md`: keyboard + focus patterns.
