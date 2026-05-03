# Corpus confidence scores

Empirical calibration of `ink-assert --confidence` against the corpus. Run with `--max-diff 2` (the tool default) on every case, score recorded as the integer the tool printed.

| Case | Verdict | Confidence |
|------|---------|------------|
| identical-favicon-twin | match | 100 |
| identical-pill-twin | match | 100 |
| pill-radius-2.5-too-small | mismatch | 61 |
| pill-radius-2-too-tight | mismatch | 49 |
| pill-radius-3-borderline | borderline | 48 |
| pill-radius-4-borderline | borderline | 40 |
| tiny-pill-dimension-mismatch | mismatch | 27 |
| pill-radius-5-too-wide | mismatch | 22 |
| favicon-vs-half-size-clearly-different | mismatch | 0 |

## Reading the table

- **Match cases score 100.** No false negatives in the current corpus. The 95-threshold is reachable on bit-perfect matches.
- **Mismatch cases score 0..61.** All sit below 95. The radius-2.5 case at 61 is the closest a mismatch comes to the threshold; that case differs from the favicon mainly on the BG-vs-AA corner split, which carries lower per-axis weight than ink-w or padding. The tool still classifies it as FAIL on the binary verdict because `pad.left` and `bgExt`/`aaExt` axes fail.
- **Borderline cases score 40..48.** They sit between the high-mismatch and the perfect-match bands, which matches their verdict semantics: neither pass nor fail, indeterminate.

## When to update this table

Re-run after any of these changes and overwrite this file:

- New axis added to `ink-assert.mjs`
- Tolerance values changed (any `--*-px` default)
- New case added to `cases/`
- `confidenceScore` weight table changed

The procedure is the bash loop documented in the comment of this file's source commit; the `corpus-confidence-scores` artefact is empirical, not derived.

## Calibration goals

The 95-threshold serves a specific purpose: it is the bar above which a candidate is interchangeable with the reference for the operator's eye. A bit-perfect twin must score 100. A clear mismatch must score below 95. Borderline cases must score below 95 but well above 0; their distance from 95 is a measure of how far the candidate sits from the irreducible cross-pipeline floor.

The current weights satisfy these constraints on the corpus. If a future case violates them (a clear mismatch scoring above 95, or a perfect twin scoring below 95), that case is the trigger to revisit the weights, not a reason to widen the threshold.
