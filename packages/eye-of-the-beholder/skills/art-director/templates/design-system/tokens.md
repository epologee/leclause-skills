# Design tokens: [Product naam]

Drie-laags taxonomie naar Nathan Curtis (medium.com/eightshapes-llc). Applicatiecode praat ALLEEN tegen de semantic laag. Primitives zijn de fysieke palet, components zijn per-component afleidingen.

## Laag 1: Primitive tokens

*De fysieke palet. Betekenisloos voor het product: `--blue-500` zegt niets over waar het gebruikt wordt. Bestaat zodat de semantic laag ergens naar kan verwijzen.*

### Kleuren (OKLCH)

```css
--blue-50:  oklch(0.97 0.02 260);
--blue-100: oklch(0.93 0.04 260);
--blue-500: oklch(0.62 0.18 260);
--blue-700: oklch(0.48 0.16 260);
--blue-900: oklch(0.28 0.12 260);

--neutral-50:  oklch(0.99 0 0);
--neutral-100: oklch(0.96 0 0);
--neutral-500: oklch(0.62 0 0);
--neutral-700: oklch(0.42 0 0);
--neutral-900: oklch(0.15 0 0);

/* + overige kleuren uit visual-language.md */
```

### Spacing

```css
--space-0:   0;
--space-1:   0.25rem;  /* 4 px */
--space-2:   0.5rem;   /* 8 px */
--space-3:   0.75rem;  /* 12 px */
--space-4:   1rem;     /* 16 px */
--space-6:   1.5rem;   /* 24 px */
--space-8:   2rem;     /* 32 px */
--space-12:  3rem;     /* 48 px */
--space-16:  4rem;     /* 64 px */
```

### Type-schaal

```css
--font-size-xs:  0.75rem;   /* 12 px */
--font-size-sm:  0.875rem;  /* 14 px */
--font-size-md:  1rem;      /* 16 px */
--font-size-lg:  1.125rem;  /* 18 px */
--font-size-xl:  1.5rem;    /* 24 px */
--font-size-2xl: 2rem;      /* 32 px */
--font-size-3xl: 3rem;      /* 48 px */

--font-weight-regular: 400;
--font-weight-medium:  500;
--font-weight-semi:    600;
--font-weight-bold:    700;

--line-height-tight: 1.15;
--line-height-base:  1.5;
--line-height-loose: 1.75;
```

### Radius + Motion

```css
--radius-0: 0;
--radius-1: 2px;
--radius-2: 4px;
--radius-3: 8px;
--radius-4: 16px;
--radius-full: 9999px;

--duration-instant: 80ms;
--duration-fast:    140ms;
--duration-base:    240ms;
--duration-slow:    360ms;

--ease-entrance: cubic-bezier(0.0, 0.0, 0.2, 1);
--ease-exit:     cubic-bezier(0.4, 0.0, 1, 1);
--ease-standard: cubic-bezier(0.4, 0.0, 0.2, 1);
```

## Laag 2: Semantic tokens

*Rol, niet kleur. Applicatiecode praat alleen met deze. Brand-wijziging = één semantic alias aanpassen, niet dertig componenten.*

```css
/* Kleur: rol */
--color-accent:         var(--blue-500);
--color-accent-hover:   var(--blue-700);
--color-danger:         oklch(0.58 0.22 25);
--color-success:        oklch(0.62 0.16 150);
--color-warning:        oklch(0.78 0.15 80);

/* Kleur: surface */
--color-surface-0:      light-dark(var(--neutral-50),  var(--neutral-900));
--color-surface-1:      light-dark(var(--neutral-100), oklch(0.19 0 0));
--color-surface-2:      light-dark(oklch(0.93 0 0),    oklch(0.23 0 0));

/* Kleur: text */
--color-text-primary:   light-dark(var(--neutral-900), var(--neutral-50));
--color-text-secondary: light-dark(var(--neutral-500), oklch(0.72 0 0));
--color-text-inverse:   light-dark(var(--neutral-50),  var(--neutral-900));

/* Spacing: rol */
--space-inline-tight:  var(--space-2);
--space-inline-base:   var(--space-3);
--space-inline-loose:  var(--space-4);
--space-stack-tight:   var(--space-2);
--space-stack-base:    var(--space-4);
--space-stack-loose:   var(--space-6);
--space-section:       var(--space-12);

/* Type: rol */
--type-body:     var(--font-size-md) / var(--line-height-base);
--type-caption:  var(--font-size-sm) / var(--line-height-base);
--type-heading:  var(--font-size-2xl) / var(--line-height-tight);
--type-display:  var(--font-size-3xl) / var(--line-height-tight);

/* Radius: rol */
--radius-control:  var(--radius-2);
--radius-container: var(--radius-3);
--radius-pill:     var(--radius-full);

/* Motion: rol */
--duration-enter: var(--duration-base);
--duration-exit:  var(--duration-fast);
```

Twee anti-patronen om te vermijden:

- **Applicatiecode die naar primitives verwijst**: `background: var(--blue-500)` in een `.button` selector is een bypass van de semantic laag. Altijd via `--color-accent`.
- **Semantic names die primitives vermomd zijn**: `--color-blue-primary` is geen semantic naam. `--color-accent` wel. Als je de hue wilt verschuiven, moet je niet ook de naam hoeven te wijzigen.

## Laag 3: Component tokens (optioneel)

*Alleen wanneer een component zijn eigen variatie nodig heeft die niet in de semantic laag thuishoort. Als je hier vaak nieuwe tokens toevoegt, is je semantic laag incompleet.*

```css
/* Button */
--button-bg-primary:       var(--color-accent);
--button-bg-primary-hover: var(--color-accent-hover);
--button-fg-primary:       var(--color-text-inverse);
--button-radius:           var(--radius-control);
--button-padding-x:        var(--space-inline-base);
--button-padding-y:        var(--space-2);

/* Card */
--card-bg:        var(--color-surface-1);
--card-radius:    var(--radius-container);
--card-padding:   var(--space-stack-loose);
--card-border:    1px solid var(--color-surface-2);
```

---

## Referenties gebruikt

- Curtis, Eightshapes Medium: 3-laags model uit Module 3.1 van SKILL.md.
- impeccable's `reference/color-and-contrast.md`: OKLCH + WCAG contrast thresholds (voor normatieve regels, verifieer je palet tegen AA/AAA na invullen).
- eye-of-the-beholder's surface-delta 1.07x rule: voor surface-0 tot surface-2 ratio-check in dark mode.
