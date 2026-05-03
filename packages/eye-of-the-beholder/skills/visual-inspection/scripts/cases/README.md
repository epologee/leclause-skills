# Validation corpus for ink-assert

Each subdirectory is one test case. Layout:

```
cases/<case-name>/
  reference.png    The "ground truth" image
  candidate.png    The candidate to compare against the reference
  verdict.txt      One of: match, mismatch, borderline
  notes.md         Optional human note explaining the verdict
```

## Verdict semantics

- **match**: the two images should pass the gate at default tolerances. The tool MUST classify this case as PASS or its accuracy is broken on the easy direction.
- **mismatch**: the two images should fail the gate at default tolerances. The tool MUST classify this case as FAIL or its accuracy is broken on the hard direction.
- **borderline**: the case sits at the cross-pipeline floor or close to a tolerance boundary. The tool MAY classify either way, but should expose the relevant axis as informational. Borderline cases are validation aids, not pass/fail anchors; they exist so the corpus runner can show that the tool's confidence score reflects the proximity to the floor.

## When the corpus runner says "FAIL on case X"

If the tool classifies a `match` case as FAIL, the gate is too strict on the relevant axis (or the axis is wrong-direction). If the tool classifies a `mismatch` case as PASS, the axis-set is missing the dimension that distinguishes the two images. Either fix is a real change to the tool, not a tolerance shuffle.

The corpus is the regression suite: every new axis added must keep all `match` cases passing and all `mismatch` cases failing. Borderline cases stay borderline.

## Adding a new case

1. Pick a name that describes the visual relationship in the directory name itself: `pill-radius-2-too-tight`, `tiny-pill-dimension-mismatch`. The name is the human-readable verdict cue.
2. Place `reference.png` and `candidate.png` cropped tightly around the elements (no extra context).
3. Write `verdict.txt` (one word, no extra whitespace handling required).
4. Optional: `notes.md` with operator ground truth, the original screenshot context, and the visual reason for the verdict.
5. Run `scripts/run-corpus.mjs` and confirm the new case classifies correctly.
