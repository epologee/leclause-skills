---
name: eye-of-the-beholder
user-invocable: true
description: Use when producing or reviewing any visual layout, color system, or animation (screen, print, responsive, transitions). Also use when the user shares a screenshot or screen recording with spacing, contrast, color-token, or timing concerns. Activates DURING and AFTER layout CSS, color token, contrast, or animation work. Catches cramped text, missing margins, disproportionate spacing, broken WCAG contrast, ad-hoc token use, snapping transitions, out-of-sync animations, and content that disappears before its container does.
---

# Eye of the Beholder

## The real problem

Claude writes CSS and only looks at the result at the end. And when Claude looks, it looks confirmingly ("I wrote padding, so there is space") rather than observationally ("what do I see?"). A designer looks a hundred times during the process. Claude looks once.

The solution is not more rules. The solution is looking more often, and looking differently.

## The core: observation before explanation

**After every layout change: screenshot. Describe what you see BEFORE looking back at the CSS.**

Not: "the padding should be 0.6rem, I see space, correct."
Instead: "I see text pressing against the top edge." Only then: why? Which CSS causes this?

This is the difference between confirmatory looking and observational looking. A doctor first describes the symptom, then the diagnosis. A designer first sees the result, then the code.

## When

In visual work, this skill is not something you call at the end. It is a working method:

1. **Write a block of layout CSS or a transition** (a container, a section, a page structure, a state transition)
2. **Screenshot or recording** (take it yourself or receive it from the user). For transitions: a GIF/MP4 or a series of frames from a headless browser.
3. **Describe what you see** in the result, without looking at the CSS. Scan clockwise: top -> right -> bottom -> left. Name the nearest element at each edge. For animations: repeat the scan on the start, mid, and end frame.
4. **Compare observation with intention.** Does something press against an edge? Does something feel cramped? Is there a void? Does something snap while the rest animates?
5. **Fix and repeat** from step 2.

This is design-TDD: the rendered result is the test, the CSS is the implementation.

## How to look

When examining a screenshot (taken yourself or provided), ask these questions in this order:

**Feel first, then measure:**

1. **Squint your eyes.** What stands out? Where does it feel cramped? Where does it feel empty? Where does your eye stop? This is Gestalt in action: the brain perceives grouping, proximity, and tension faster than conscious thought.

2. **Trace the edges.** Top -> right -> bottom -> left. What is the nearest element to each edge? How much space is between them? Does anything touch the edge?

   **Trace is fractal.** Do this at every level where something has an edge:
   - Page vs. viewport
   - Container vs. parent padding
   - Component vs. its own border/padding
   - Glyph or icon vs. viewBox or bounding box
   - Path/stroke vs. pixel-grid

   The same rules work at every level. An icon clipped within its viewBox is the same problem as a title touching the page edge, just one zoom step deeper.

3. **Look for the rhythm.** Are the distances between repeating elements (sections, cards, rows) consistent? Is the rhythm broken anywhere?

   **Internal rhythm is a separate judgment.** Measuring perimeter padding ("content is 32px from the edge") is not the same as measuring sibling gaps. Walk through each visual block within the container (title, paragraph, table, list, quote, signature, footer) and name the vertical space between each adjacent pair. Do two blocks touch each other? Is the gap smaller than the line-height of the body font? Are the gaps mutually consistent? A card with generous outer margins but collapsed internal blocks does not read as a document; it reads as dumped text in a box. This is "collapsed padding": the outer edge is fine, the inner housekeeping is not. Margin-collapse through the container padding is a known mechanism (first child margin-top collapses through parent padding-top if the parent has no border/padding/inline-content above the child); if you suspect this, check with DevTools or fix with `display: flow-root` / an explicit border-top.

4. **Look for the odd one out.** Is there an element that is just slightly different from the rest? Something that is almost the same but not quite? That is probably a bug, not a variation.

5. **Name every touch.** Which elements touch each other? Which elements touch an edge? Which elements fall outside their container? List them. For each: is this intentional? A border touching its container is usually deliberate. Text touching the page edge almost never is. Intentional touches are explicit (e.g. a `bleed` class), unintentional ones are bugs.

6. **Glyph and icon check.** For each vector icon or glyph in the screenshot: does the content fit within its own container? An icon that feels "cut off" at one edge is almost always a path running outside its viewBox. SVG has default `overflow: hidden`, so the clip is silent. For stroke-based icons: add half the stroke-width to the path bounds (with `stroke-width="1.5"` the actual edge lies at `coordinate ± 0.75`). Always fix by making the viewBox larger or the path smaller, never with `overflow="visible"` (that moves the problem to the parent).

7. **Optical vs. mathematical bounds.** Circles, triangles, and round glyphs weigh optically less than squares with the same mathematical bounds. Designers compensate with *overshoot*: an "O" is fractionally larger than an "H", a circle must be ~113% of a square to read as equally large, a triangle must have its sharp point extend past the baseline. Does a round shape feel "smaller" than a square neighbor of the same pixel size? That is not an illusion, it is a missing overshoot.

8. **Optical center sits higher than geometric center (Arnheim).** Mathematically centered content feels top-heavy. Push the visual center of gravity 2-5% upward. This is why `align-items: center` in CSS often feels "just too low": it is mathematically correct, not optically correct.

   **Exception for typography in icon containers** (buttons, pills, badges): here the rule works *in reverse*. A digit or letter naturally sits high within its line-box because font ascent is greater than font descent (typically 80/20). Cap-height center sits ~5% above em-box center. In a pill with an SVG icon that IS symmetrical, text feels "too high" (more whitespace below than above). Spiekermann's rule: *align to cap-height center, not to glyph bounding box*. Fix via micro-translate (~0.5-1px) or via `text-box-trim` / cap-height line-height libraries (Braid's capsize). In a review: do you see text and icon that do not feel equally centered in their container, with text higher than icon? That is font metric asymmetry, not your brain.

9. **Compare left with right, top with bottom.** Is the composition balanced? Not necessarily symmetrical, but intentional? Symmetrical composition often feels dull; asymmetric balance via visual weighting (color, contrast, mass) is livelier (Arnheim).

10. **How is this held?** The design borders on the physical world. Paper is held with fingers that cover the edges. A phone screen has bezels (or no longer does). A laptop has a frame. The design's margins must account for what the user physically covers.

**Tschichold's margin ratios for printed work: 1:1:2:3** (inner:top:outer:bottom). The bottom margin is largest because hands hold the paper there. The Van de Graaf canon from medieval manuscripts: 2:3:4:6. The same logic, even more dramatic.

**The medium mutates.** Smartphone bezels used to be thick, now nearly invisible. When bezels were thick, UI margins did not need to be large (fingers touched plastic, not pixels). Now bezels are gone, fingers cover the interface, so UI margins must grow. Apple's safe area insets grew along with shrinking bezels. For print the opposite is true: paper has no bezel, only paper. The "bezel" is zero, so the margin must compensate for everything.

**Practically:** for a loose A4 sheet held in hands, the outer and bottom margins matter most. A recipe on the counter is held at the top or side. The margins must be large enough that fingers do not cover text.

**Only then measure and fix:**

**Measuring and judging is one action, not two.** Writing down a pixel value is not a completed observation; only when that value has been tested against a standard or ratio is the finding complete. "There is 20px padding" is half a sentence. "20px padding on 14px body-font = 1.4x, below the 2.5x threshold for comfortable document reading" is a finding. The scan only ends when every measured value has an explicit verdict: good, cramped, generous, fails.

**Default ratios to test against:**
- Padding/gutter around body text: minimum 2.5x body-font size. Below that threshold it feels cramped, even if nothing is touching.
- Document-metaphor canvases (email-body, card-as-paper, editor-surface): Tschichold 1:1:2:3 (inner:top:outer:bottom) as starting point. Web-style 16-24px all around does not qualify; a document wants 2-3rem+ space around the text.
- Section gap vs. internal gap: minimum 2x difference to convey hierarchy. "14px vs 5px = 2.8:1" works; "14px vs 10px = 1.4:1" is ambiguous.
- Adjacent surface levels: minimum 1.07x luminance ratio (see color section).

Express problems as ratios, not pixels:
- "The title is at 0px from the top, but the body font is 12px. There should be at least 2.5x font size (~30px) there."
- "The section gap is 14px but the internal gap is 5px. That is a 2.8:1 ratio, clear enough."
- "This is a printed A4 sheet. Tschichold's ratio 1:1:2:3 at a 1.5cm base gives: top 1.5cm, inner 1.5cm, outer 3cm, bottom 4.5cm."
- "Email-body card has 20/24px padding on 14px body-font = 1.4x/1.7x. Below the 2.5x threshold, and far below Tschichold for document canvas. Cramped."

## Color: the same discipline, a different axis

Space is one axis on which you look observationally. Color is a second. The same attitude works: not "these two cells both have a border so they are separated" but "do I see the difference?" Not "it says `text-muted` so the text is readable" but "can I comfortably read this without squinting?"

### Visual color observation

Add these questions to the scan in "How to look":

11. **How many shades of gray do you see?** Count them in the screenshot. A disciplined system has few and uses them consistently. Ten subtle variants is not subtlety; it is ten separate choices that happen to live in the same repo.

12. **Adjacent surfaces.** Are two "different" surfaces next to each other (canvas vs. list pane, list vs. detail)? Do you see the distinction immediately, or do you have to search? If you have to search, the luminance delta is too small. This is especially a trap in dark mode.

13. **Can you read secondary text without squinting?** Metadata, timestamps, captions. If you instinctively enlarge it or lean closer, it fails WCAG AA. That is not a matter of taste but a structural error.

14. **Warning and status colors.** Are "red for error" and "green for ok" clear enough? Failure text on a white background must pass AA, just like body text. Tailwind's `red-500` and `green-500` usually just barely fail on white. Darker (`red-700`, `green-700`) passes.

### Looking beneath the screenshot: the token system

A screenshot can look fine while the system underneath is messy. Three audits done at code level, not on the image:

**1. Token vocabulary scan.** Grep in the component layer for the bypass patterns:

- Opacity modifiers on color utilities (Tailwind `text-foo/50`, `bg-foo/20`): usually a sign of a missing tint, not a deliberate opacity. The developer needed a third text level and only two existed.
- Palette colors in app code (`text-red-500`, `bg-blue-200`): bypasses the semantic system. Every use is a question "why wouldn't `text-danger` have worked here?"
- Hardcoded hex/rgb/oklch in style blocks (`color: #94a3b8`): a framework-free escape. Usually because the token system had no suitable word.
- Undefined tokens that are used anyway (`bg-surface-muted` when that token does not exist): Tailwind v4 generates no class and silently falls back to nothing. If you see an empty background where you expect color, check the theme definition.

Each of these patterns signals an incomplete token system. The fix is rarely "add a token" (reactive, repeats the problem). The fix is "revise the vocabulary until every role that appears in the UI has its own name."

**2. WCAG contrast math.** For each text color used on each background used, calculate the ratio. You do not need to squint; the math gives the definitive answer.

For the AA/AAA threshold table, including the reasoning behind 4.5:1 and 3:1, see impeccable's `reference/color-and-contrast.md`. The formula below stays here because observational work often needs to calculate a ratio on the spot without switching tools.

WCAG 2.1 SC 1.4.3 formula:

```
Per channel c (R, G, B):
  c_norm = c / 255
  c_lin  = c_norm ≤ 0.03928 ? c_norm / 12.92 : ((c_norm + 0.055) / 1.055)^2.4

Luminance:
  L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin

Ratio of two colors:
  ratio = (L_lighter + 0.05) / (L_darker + 0.05)
```

Thresholds:

| Use                                             | AA     | AAA  |
| ----------------------------------------------- | ------ | ---- |
| Body text (< 18pt regular, < 14pt bold)         | 4.5:1  | 7:1  |
| Large text (≥ 18pt, or ≥ 14pt bold)             | 3:1    | 4.5:1 |
| UI component boundary (button, input, control)  | 3:1    | -    |
| Decorative dividers / non-functional borders    | exempt | -    |

A small script in Ruby, Python, or JavaScript saves hours of visual doubt. Run it for every fg/bg combination the app actually uses, not for all theoretical combinations.

**3. Perceptual surface delta.** Adjacent surface levels (canvas, list pane, detail pane, hover, active) must be visually distinguishable. Minimum: **1.07x luminance ratio** between adjacent levels. Below that threshold the system claims hierarchy that does not exist optically.

This is especially a trap in dark mode. Absolute luminance values are small there (typically 0.003 - 0.02), so an absolute delta of 0.004 looks substantial in a spreadsheet but is perceptually zero. Always check the ratio, not the difference.

**Light and dark are two designs, not one.** If you fill a role (`surface-1`) correctly in light and then make dark mode "somewhere dark", you have two different semantic systems that happen to share a name. Every role must carry the same meaning in both modes: if `surface-1` is the most prominent reading surface in light, it must be that in dark too. Use `light-dark(light, dark)` in CSS custom properties so both values live side by side in the same rule and do not drift apart.

## Animation: the same discipline, time as the axis

Space and color are two axes. Time is a third. The same attitude works: not "I wrote `transition: transform 200ms`, so it animates smoothly" but "what do I see between frame 0 and frame 12?" The screenshot becomes a *series* of screenshots. The edge trace happens on each key frame. The rhythm is the timing curve. The "odd one out" is the one element that falls out of sync.

A static end state that looks correct says nothing about the journey to get there. A UI that is neatly laid out before and after animating can collapse badly in between.

### Visual animation observation

Add these questions to the scan in "How to look". They are applied to a *series* of frames (start, quarter, half, three-quarter, end) rather than a single screenshot:

15. **Do all elements that belong together move as one?** When a header and its content both end at new positions, they must have the same *tempo* during the transition. Does the header snap while the content animates, or does one stop at 80% while the other is at 60%? This is rhythm on the time axis. A component that falls out of sync is the "odd one out" of animation.

16. **What happens to disappearing content?** Does an element collapse instantly while its container is still moving? That is a "teleporting element": it departs before its vehicle has left. You expect content to travel along until the journey ends. Fix pattern: `transition: visibility 0s linear var(--duration)` on the hidden state so the visibility flip only happens AFTER the movement finishes. Mirror image: does content only appear after its container has already moved? Then the entry is broken; visibility must flip instantly instead.

17. **Does everything start and end at the same moment?** Check the transition delay, duration, and easing of each animating element via `getComputedStyle`. Different durations are sometimes intentional (stagger) but more often a bug. "Nav snaps, content animates 200ms" is rarely expressive, usually a forgotten `transition` rule on the nav.

18. **Is a cell that is "hidden" truly gone or just invisible?** Parking off-screen (visibility hidden with full renderWidth) and collapsing to 0 (width 0, display none) look the same in a static screenshot. Under movement they do not: a parked cell can slide as one unit with the rest, a collapsed cell snaps away. For slide-style transitions: park, do not collapse.

19. **Timing versus distance.** A 200ms transition feels fast for a 50px shift and slow for an 800px shift. When multiple transitions run simultaneously with different distances, this becomes visible. The question is not "is the duration right?" but "is the SPEED (px/ms) correct for what I am communicating?" In large column shifts a shorter duration is sometimes more expressive than the same 200ms you use everywhere.

### Looking beneath the screenshot: timing and sync

A transition can look correct on a single frame but be out of sync under the hood. Code-level audits, just like the token vocabulary scan:

**1. Timing source scan.** Grep for hardcoded durations and easings in component code:

- Numeric ms/s values in CSS (`200ms`, `0.3s`): usually a missing custom property. If two elements in the same flow both hardcode `200ms` separately, they will drift apart at the first refactor.
- Hardcoded cubic-bezier or named ease (`ease`, `ease-out`, `cubic-bezier(...)`): same problem. Define a `--duration-*` and `--ease-*` vocabulary and use it everywhere.
- `transition: all`: almost always wrong. "All" includes properties you did not mean to animate (color, border) and properties that trigger layout (width, padding). Be explicit: `transition: transform var(--duration) var(--ease), opacity ...`.
- Svelte/React animation libs in places where CSS transitions would suffice: extra bundle, extra concept, usually not needed for state-to-state transitions.

**2. Sync audit.** For a flow where multiple elements must move together: explicitly list what does and what does not transition. An element receiving an inline `style:width` without a `transition` rule on it is a snapping element. That is the one quick check pattern you can run yourself via `grep -n "style:" --include="*.svelte"`.

**3. Compositor-only properties.** Transform and opacity are animated by the compositor without layout. Width, top, left, padding, margin are layout properties and trigger reflow per frame. For small elements that is fine. For rows of 5+ items or with parallel transitions it can jank. `contain: layout` on animating children isolates the reflow to their own box. `will-change: transform` (not `will-change: width`, which is an anti-pattern per MDN) promotes the element to its own layer.

The normative rule "transform and opacity only" for animations also lives in impeccable's `reference/motion-design.md`. What stays here: the observational diagnosis (reflow check on rows, `contain: layout` as a tactical fix, `will-change: width` as a specific anti-pattern) because those are about recognizing an existing problem, not about which rule to follow while building.

### Recording and dissecting yourself

Verifying an animation without recording it is the same as verifying a layout without a screenshot. Workflow:

**1. Reproduce.** User provides a GIF or MP4, OR you record it yourself. Self-recording options:

- **Headless browser test driver** (Cuprite, Playwright): `session.driver.save_screenshot(path, full: true)` in a loop with `sleep` in between, or sequential snapshots with explicit viewport resizes.
- **Screen recording** (macOS: CleanShot, Cmd+Shift+5): quick but manual.
- **Chrome DevTools Recorder**: structured, when you want to reproduce a user flow.

Save the recording to `tmp/` or a scratch directory that is gitignored.

**2. Dissect.** Frame extraction via `ffmpeg`:

```bash
ffmpeg -i capture.mp4 -vf "fps=15,scale=900:-1" /tmp/frame_%03d.png
```

`fps=15` is enough for 200-400ms transitions (3-6 frames over the animation). `scale=900:-1` keeps file sizes small so the Read tool can view the frames. For longer or more subtle animations: increase to `fps=30` and live with the larger files.

Read the frames via the Read tool. Per frame: apply the scan questions from "How to look" (edges, rhythm, odd one out). Compare frame N with frame N+1: what changed, what should not have changed, what SHOULD have changed?

**3. Self-capture verification.** After a fix: record a new capture yourself to prove the problem is gone. Same workflow.

**4. Mid-animation inspection.** Rest-state screenshots only prove the end positions, not the journey. For intermediate inspection:

- **Slow-mo trick**: override the duration custom property via JS in a test: `document.querySelector('.root').style.setProperty('--duration', '1s')`. Trigger the transition, sleep 100-500ms, sample `getComputedStyle(element).transform` or `.visibility`. The 5x or 10x slowdown gives you a wide window to read mid-animation values.
- **Multiple samples**: at t=50, 100, 150, 200ms take a snapshot, verify that the values interpolate monotonically and that related elements are in sync at each sample point.

**5. Rest-vs-mid testing.** An animation test that only checks rest state is broken by definition: it cannot fail on the halfway-through-the-animation bugs the user actually experiences. Write an explicit mid-animation assertion when it is critical that elements run in sync. The slow-mo trick makes this writable in Cucumber/Playwright without race conditions.

### Pixel-level animation sampling

When you look at frames visually and the movements seem "roughly right", or you cannot tell whether a progress bar is retreating from 10% to 5%, that is the image-viewer limit: a 4px-wide bar over a 60px-tall row renders a 5% difference as 3 pixels. You cannot see that in a scaled-compressed image view. You need to read the pixel data directly from the frames.

**Technique**: ffmpeg extracts a 1-pixel-wide vertical slice at the bar position, per frame. Decode the raw RGB bytes from a PPM header. Classify each pixel as `P` (purple/selected), `A` (amber/unread), `.` (background) based on RGB thresholds. Count the P and A pixels per frame to get an exact percentage.

```javascript
const { execSync } = require('child_process')
const fs = require('fs')

const X = 29  // bar x-position in the GIF (measure beforehand via a single slice)
const gif = '/tmp/capture.gif'

function classify(r, g, b) {
  if (b > 150 && r < 180) return 'P'                    // purple/violet
  if (r > 200 && g > 140 && g < 190 && b < 120) return 'A'  // amber
  if (r > 200 && g > 200 && b > 200) return '.'         // background
  return '?'                                             // transition state
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

**The output gives the true picture that image view cannot deliver.** You do not just see that the bar goes from amber to purple; you see exactly that on frame 13 there is a jump to 28%, on frame 14 a peak to 33%, on frame 27 a low of 12%, etc. Only with this data can you work backwards to determine which CSS transition, $effect race, or JS reset is the cause.

**When to use**:
- A user reports a bug in an animation that you cannot see visually.
- You are unsure whether a progress bar fills linearly or has overshoot.
- You see a peak/dip/oscillation and want to know how large it is.
- Two elements animate simultaneously and you want to know whether they run in sync.

**When not needed**:
- Gross movement (entire element repositions, opacity 0 to 1).
- A difference of 20%+ that you can see with the naked eye.

**Rule of thumb**: if the user says "there is still a flicker/retreat/jitter" twice and you cannot see it, move from visual inspection to pixel sampling. Image view simply does not have the resolution for sub-5% movements.

## Foundation

**Robin Williams (CRAP):** Contrast (make differences unmistakable or make them equal), Repetition (repeat visual choices for coherence), Alignment (everything must be visually connected to something else), Proximity (nearness implies relation).

**Gestalt (Wertheimer, Koffka):** The brain seeks the simplest interpretation (Pragnanz). Equal elements are perceived as a group (Similarity). This is why a 12-year-old "sees" spacing problems and Claude does not: the brain does it automatically, Claude must do it deliberately.

**Muller-Brockmann (Grid Systems):** Derive all spacing values from a shared base. The grid is a discipline that prevents arbitrariness.

**Tufte:** Maximize the data-ink ratio. Every visual element must contribute to understanding. **Tschichold:** White space is an active design element, not what remains.

**Arnheim (Art and Visual Perception):** Visual center of gravity matters more than pixel center. Optical center lies above geometric center. Asymmetric balance via visual weighting (mass, contrast, color) is livelier than strict symmetry.

**Apple HIG / Material Design / Lucide (icon grids):** Every icon has two bounding boxes. An outer canvas and an inner "live area". Primary content stays within the live area, secondary content may extend to the outer, never beyond. Material: 24x24 canvas, 20x20 live area, 2 dp padding all around. Lucide: 24x24 canvas, 22x22 live area, stroke-width 2 centered (which pushes the actual edge a further half-stroke outward). Apple SF Symbols: inner icon-grid box plus outer bounding box. An icon that touches the outer edge feels out of place.

**Bjango / Spiekermann (optical adjustments):** Mathematically identical shapes are optically unequal. Circles must overshoot the baseline and x-height. Sharp points of triangles must extend outside the bounding box. Vertical lines must appear thicker than horizontal ones to weigh equally. It is not an illusion to be fixed, it is how eyes work.

## Division of labor with art-director and impeccable

Eye-of-the-beholder is diagnostic. It looks at what IS there and compares it to intent. Two sister skills are responsible for other moments in the chain.

**art-director** (same plugin, sister skill) works upstream. Before CSS exists: define brand (who are we), visual language (how do we speak visually), and design-system architecture (how does this scale). Delivers `brand.md`, `visual-language.md`, and a `design-system/` skeleton. When eye-of-the-beholder observes that a hue does not fit or a spacing does not rhythm, the underlying standard should live in art-director's artifacts, not in every reviewer's head.

**impeccable** (external plugin) uses the standard while building. Per feature. Contains the normative rules in `reference/color-and-contrast.md`, `motion-design.md`, `typography.md`, `spatial-design.md`, and others. Eye-of-the-beholder refers to impeccable for the rules; impeccable refers to art-director's artifacts for the concrete brand choices within those rules.

The chain over time: art-director once (for a new product, brand refresh, first DS foundation), impeccable per feature while building, eye-of-the-beholder per change afterward to verify visually. When eye-of-the-beholder signals a problem that does not sit in a single view but occurs system-wide (e.g. an uncoordinated spacing scale), that is a signal that art-director work is incomplete or missing.

## Common blind spots

| What Claude does | What goes wrong |
|-----------------|----------------|
| Writing `padding: 0.6rem 0` | The 0 is zero space left/right. Read every value. |
| Placing an element outside the main container | That element inherits no padding. It needs its own spacing. |
| Looking at the center, not the edges | The center always looks fine. The errors live at the edges. |
| Measuring only perimeter padding, not sibling gaps | Container has 32px all around, but a paragraph touches the table below. Collapsed padding. Walk explicitly through each sibling pair inside the container. |
| `:host` / container padding passed through by margin-collapse | First child margin-top collapses through parent padding-top if the parent has no border/padding between. Fix with `display: flow-root` or an explicit border-top. |
| "Does it fit?" as an evaluation criterion | Fit is not quality. Something can fit and still look bad. |
| Making a fix and stopping | Every fix triggers a rescan of all four edges. |
| Reading CSS as evidence | CSS describes intent, not result. The screenshot is the truth. |
| Shrinking font sizes to make things fit | Shrinking is always wrong. Restructure the layout. |
| SVG path filling the viewBox to the edge | Default `overflow: hidden` clips silently. Leave 1-2 units of margin, or enlarge the viewBox. |
| Forgetting stroke-width in a bounds check | Centered stroke adds `width/2` to all sides. A path to y=16 with stroke=2 effectively ends at y=17. |
| Mathematically centering a glyph | Optical center is higher. Push 2-5% upward. |
| Making a round shape equal to a square one | Circles must be ~113% to weigh optically equal. |
| Only tracing the page edges | Trace is fractal. Every container with edges deserves an edge trace: component, glyph, path, pixel. |
| Symmetrically centering text and icon in a pill | Font ascent > descent makes digits appear optically high. Align to cap-height center, not bounding box. Micro-translate of 0.5-1px or cap-height line-height. |
| Opacity modifier as a third text color (`text-foo/50`) | You have a missing tertiary level, not half-text. Define an explicit token. |
| Palette color in app code (`text-red-500`) | Semantic bypass. Replace with `text-danger` or equivalent. |
| Hardcoded hex in a component style block | Missing token. Define a new role, or use an existing token that fits. |
| "Dark mode looks fine" without math | Check the ratios. Surface delta below 1.07x is invisible, text contrast below 4.5 fails AA. |
| Two adjacent surfaces where you see no difference | The difference IS not there. Increase the luminance delta to at least 1.07x. |
| Color values for light without a counterpart for dark | Both modes are separate designs. Use `light-dark(L, D)` so they live side by side. |
| Only rest-state screenshots for animation | The journey is the bug. Take frames or use the slow-mo trick to inspect mid-animation. |
| Judging progress animations on regular screenshots | 5% differences in bar-fill are invisible on normal image view. Sample pixels directly from frames. See "Pixel-level animation sampling" section. |
| Content disappearing before its container | Teleporting element. Delay `visibility: hidden` with `transition: visibility 0s linear var(--duration)` on the hidden state. |
| Hardcoded ms/ease scattered across components | Define `--duration-*` and `--ease-*` custom properties, use everywhere. Otherwise elements drift apart at the first refactor. |
| `transition: all` | Animates color, border, layout props too. Explicit: `transform var(--dur), opacity var(--dur)`. |
| `will-change: width` | Anti-pattern per MDN. Width is a layout property and gets no GPU compositing. Only use `will-change: transform` / `opacity`. |
| Inline `style:width` without a `transition` rule | Snaps instantly. Grep for `style:` in components to find snapping elements. |
| Cells collapsing to 0 instead of parking off-screen | Collapse forces "from nothing to something" jumps. Park via visibility-hidden with retained renderWidth. |

## Output

After viewing a screenshot:

```
Observation (before I look at the CSS):
- Top: the title touches the top of the page
- Right: sufficient space
- Bottom: ~25% white at the bottom, feels empty
- Left: the title starts further left than the step-content
- Rhythm: steps are evenly distributed
- Odd one out: step 3 has less content, feels narrower

Diagnosis (after CSS check):
- .print-header has padding: 0.6rem 0 (zero left/right)
- .print-header has no margin-top (presses against content-area top)

Fix:
- padding: 0.6rem 0.9rem (0.9rem = 3x base unit, equal to .main padding-x)
```

After viewing a series of frames (animation):

```
Observation per frame (before I look at the CSS):
- Frame 0 (start): nav shows 3 titles, content shows 3 cells, everything neatly in rhythm.
- Frame 3 (mid): nav is already at the new layout with 2 titles, content is halfway.
  The nav titles have snapped, the cells are still animating.
- Frame 6 (end): nav and content both in final position.
- Odd one out: the nav is not in rhythm with the content. They end together but
  do not start together.
- Disappearing content: in frame 3 the content of the sliding-away cell is already
  hidden while its container is still moving. Teleporting element.

Diagnosis (after CSS check):
- .nav-title has inline style:width but no `transition` rule in the CSS.
- .cell-collapsed sets visibility: hidden instantly without a delay.

Fix:
- .nav-title gets transition: width var(--duration) var(--ease).
- .cell-collapsed gets transition: visibility 0s linear var(--duration), so
  the visibility only flips after the movement is complete.
```
