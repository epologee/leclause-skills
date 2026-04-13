# References

Bronnen voor de regels in SKILL.md. Gegrond in bestaande design-literatuur en icon system documentatie.

## CRAP (Contrast, Repetition, Alignment, Proximity)

Robin Williams, *The Non-Designer's Design Book* (1994, Peachpit Press). De vier principes die elk beginnend designer leert. Gedekt in de Fundament sectie.

## Gestalt

Max Wertheimer, Kurt Koffka (1920s). *Pragnanz* (eenvoud), *Similarity* (gelijke elementen groeperen), *Proximity* (nabijheid impliceert relatie), *Closure* (brein vult lacunes in), *Continuity* (oog volgt vloeiende lijnen).

## Grid discipline

Josef Muller-Brockmann, *Grid Systems in Graphic Design* (1981). Alle spacing afgeleid van een gedeelde basis.

## Data-ink ratio

Edward Tufte, *The Visual Display of Quantitative Information* (1983). Maximaliseer het aandeel "inkt" dat direct data representeert.

## Print margins (1:1:2:3)

Jan Tschichold, *The Form of the Book* (1991, Hartley & Marks). Marge-verhoudingen binnen:boven:buiten:onder = 1:1:2:3. Van de Graaf canon uit middeleeuwse manuscripten: 2:3:4:6.

## Visuele balans en optisch centrum

Rudolf Arnheim, *Art and Visual Perception: A Psychology of the Creative Eye* (1954, University of California Press). Visueel zwaartepunt, optisch centrum ligt boven geometrisch midden, asymmetrische balans via visuele weging.

## Icon grids

- **Apple Human Interface Guidelines, Icons**: https://developer.apple.com/design/human-interface-guidelines/icons. Inner icon-grid bounding box (primaire content) en outer bounding box (secundaire content). "If an icon's primary content extends beyond the icon grid bounding box, it tends to look out of place."
- **Material Design, Metrics & Keylines**: https://m1.material.io/style/icons.html. Canvas 24x24 dp, live area 20x20 dp, 4 dp padding rondom. Dense variant: 20x20 canvas, 16x16 live area, 2 dp padding.
- **Lucide Icon Design Guide**: https://lucide.dev/contribute/icon-design-guide. 24x24 viewBox, minimaal 1 px padding binnen canvas, stroke-width 2 centered. Feitelijke rand zit op `coordinaat +- 1` door de gecentreerde stroke.

## Optische correcties

- **Bjango, Formulas for optical adjustments**: https://bjango.com/articles/opticaladjustments/. "A square and a circle with matching width and height do not look like they are the same weight. The circle seems smaller." Een cirkel moet ~112.84% van een vierkant zijn om optisch gelijk te wegen.
- **Erik Spiekermann, *Stop Stealing Sheep and Find Out How Type Works*** (1993). Overshoot in typografie: ronde letterformen steken buiten baseline en x-height. Ook: digits en letters moeten worden gealigneerd op cap-height center, niet op glyph bounding box, vanwege ascent/descent asymmetry in font metrics.
- **Braid Design, Capsize**: https://seek-oss.github.io/capsize/. Library en artikel over cap-height line-height. "Flex centering in CSS uses the line-box, not the cap-height, which means text appears visually offset from center in buttons and badges." Fix via calculated line-height of `text-box-trim: trim-both cap alphabetic`.
- **CSS WG, `text-box-trim`**: https://www.w3.org/TR/css-inline-3/#text-edges. Nieuwe CSS property om line-box trimming op cap-height/baseline te doen. Browser support 2024+.

## SVG overflow default

- **CSS-Tricks, 6 Common SVG Fails**: https://css-tricks.com/6-common-svg-fails-and-how-to-fix-them/. "By default, the CSS overflow value of svg elements is set to hidden, meaning anything outside of the viewBox gets clipped off." Fix via `overflow="visible"` is een workaround, niet een oplossing.
- **SVG spec, viewBox**: https://www.w3.org/TR/SVG11/coords.html#ViewBoxAttribute.

## Pixel-perfect vector work

- **iconvectors.io, Pixel-Perfect SVG Setup**: https://iconvectors.io/tutorials/make-pixel-perfect-svg-icons.html. Even strokes (2, 4) op integer coordinates, odd strokes (1, 3) op `.5` offsets. Export naar bitmap 1x/2x om edges te inspecteren.

## Canon (algemeen)

Massimo Vignelli, *The Vignelli Canon* (2010, Lars Muller). Gratis beschikbaar. Discipline over creativiteit, bewuste beperking van keuzes.
