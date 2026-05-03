# Pipeline floors

Per-axis irreducible floor when comparing a CSS-rendered candidate against a canvas-PNG reference at the same display size. The floor is the smallest delta the gate can hit no matter how the candidate's CSS is tuned, because the rendering pipelines differ at the rasterization level.

A floor is "irreducible" when no CSS knob can move the axis any closer to the reference without breaking another axis. A floor is "reducible-with-effect" when a side-effect knob (typically `filter:blur` or a stacked `box-shadow`) can reduce the floor at the cost of fidelity on a different axis.

Reference baseline: 32x32 device-pixel canvas-PNG favicon, dark squircle plus orange "31" digits, drawn via the same `renderFaviconBadge` function the inbox-zero project uses. Candidate baseline: a CSS pill rendered at 16 CSS pixels at DPR 2 with `width:16px`, `height:16px`, `display:inline-flex`, `font-family:ui-sans-serif`.

## Floors

| Axis | Floor (delta) | Type | Notes |
|------|---------------|------|-------|
| frame.w | 0 | reachable | Use `width:16px` and `flex-shrink:0` to lock the bbox. Without `flex-shrink:0` a parent flex container can squeeze the pill below 16. |
| frame.h | 0 | reachable | Same as frame.w with `height:16px`. |
| ink.w | 1 device px | irreducible | CSS-text and canvas-text differ on glyph advance widths by 1 device pixel for "31" at DPR 2. |
| ink.h | 0..1 device px | reachable | Cap-height matches across pipelines for sans-serif at small sizes. |
| pad.top/bottom | 0..1 device px | reachable | The 0.25 CSS-pixel asymmetry caused by font ascent vs descent rasterizes to 1 device px at DPR 2. Either accept (Arnheim bias up) or use `[&>span]:translate-y-[0.25px]` to shift the asymmetry. |
| pad.left/right | 0..1 device px | reachable | Glyph metrics produce sub-pixel asymmetry similar to vertical. |
| corner.TL/TR/BL/BR (diag) | 0 | reachable | Pure CSS border-radius can match the canvas's nearest-curve-point inset to within 1 px. |
| bgDiag.* | irreducible to 0 | irreducible | At the corner pixel (0,0) of the frame bbox, CSS border-radius leaves a pure BG pixel where the canvas-PNG has an EDGE pixel due to AA. The corner pixel itself cannot be painted by any border-radius value. Only `filter:blur` or `box-shadow` can reduce this floor. |
| aaDiag.* | irreducible to 0 | irreducible | Mirror of bgDiag. CSS border-radius produces 0 EDGE pixels in the corner; canvas-PNG produces 2-4. `filter:blur(0.3px)` reduces the floor at the cost of glyph blur. |
| edgeExt.* (legacy) | 1-2 px | reachable | Sum of bgExt and aaExt; can be matched by tuning border-radius, but the SUM matches while the SPLIT does not (this is why the split exists). |
| bgExt.* | irreducible without filter | irreducible | Same source as bgDiag: CSS hard cutoff vs canvas soft fade. |
| aaExt.* | irreducible without filter | irreducible | Same source as aaDiag. |
| halo.* | irreducible to ~3 EDGE pixels | irreducible | Canvas-PNG produces ~5-7 EDGE pixels in the 5x5 corner block; CSS produces 0-3. `filter:blur(0.3-0.5px)` raises CSS halo to match. |
| hist.INK | reducible to <2% | reachable | Tune font-size and font-weight to match the favicon's ink area. |
| hist.FRAME | reducible to <2% | reachable | Follows from hist.INK plus border-radius (corners trade FRAME for BG/EDGE). |
| hist.EDGE | irreducible to ~3% delta | irreducible | CSS hard edges produce few EDGE pixels; canvas AA produces ~8%. `filter:blur` closes the gap. |
| hist.BG | irreducible to ~2% delta | irreducible | Inverse of hist.EDGE: CSS leaves BG where canvas has EDGE. |
| ms.32x32.meanRGB | <2 RGB units | reachable | Coarse-scale color balance is matchable. |
| ms.1x1.meanRGB | <8 RGB units | irreducible-when-corner-AA-differs | When AA halos differ, the integrated color over the whole frame differs at 1x1. Floor follows the AA-axes. |
| pixel diff | 15-25% | irreducible | Cross-pipeline AA on glyph and corner pixels produces inevitable per-pixel deltas at threshold 24/255. The exact floor depends on glyph rendering: bolder weights on the candidate close the digit-AA gap and lower the floor toward 15%; defaults sit around 20%. |

## Implications for confidence

The `--confidence` scoring penalises every failed axis without distinguishing reachable from irreducible failures. A confidence below 95 is a "we are not at the twin-grade match" signal, not a "the gate broke" signal. When the failures are all on the irreducible-floor axes, read the score as "the cross-pipeline floor was reached, anything closer requires changing the rendering pipeline of one side".

The score-to-floor relationship is empirical: the corpus-measured calibration in `corpus-confidence-scores.md` shows what each case scores under the current weights, so the operator can compare a candidate's score against where the corpus's match, mismatch, and borderline cases land.

## How to extend this catalogue

When a new axis is added to `ink-assert`:

1. Run the corpus and observe how the new axis behaves on the borderline cases (radius 3 and 4 favicon-vs-pill).
2. Try every CSS knob in `direction-matrix.md` against the reference and see if any combination closes the new axis's gap.
3. If yes: floor is "reachable" or "reducible-with-effect", document the specific CSS variant.
4. If no: floor is "irreducible", document the cause (which pipeline produces the diverging pixels, and why).

The catalogue is empirical, not derived. Add measurements, do not infer values from theory.
