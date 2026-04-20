# eye-of-the-beholder

Visual layout review. Observation before explanation: screenshot first, describe what you see, then diagnose. Design-TDD for CSS.

Catches cramped text, missing margins, disproportionate spacing, broken WCAG contrast, ad-hoc token use, snapping transitions, out-of-sync animations, and content that disappears before its container does.

This plugin ships two sister skills:

- **`/eye-of-the-beholder`** (default): diagnostic, per-change visual review.
- **`/art-director`**: upstream identity work. Captures brand, visual language, and design-system architecture BEFORE CSS exists. Not for small UI tweaks; for new products, brand refreshes, or first-time design-system foundation.

## Commands

### `/eye-of-the-beholder`

Reviews the current visual state. Captures a screenshot, lists concrete observations, then maps each observation to a diagnosis (token, spacing scale, contrast ratio, animation timing).

### `/art-director`

Produces `brand.md` + `visual-language.md` + `design-system/` skeleton from stakeholder interviews, competitive scan, and brand strategy. Three modules: brand identity discovery (Wheeler), visual language translation across type / color / form / motion / photography, and design-system architecture with the Curtis 3-layer token model and Frost atomic component taxonomy. Artefacts become the standard that impeccable applies per feature and eye-of-the-beholder verifies per change.

## Auto-trigger

`/eye-of-the-beholder` activates DURING and AFTER layout CSS, color token, contrast, or animation work. Also activates when the user shares a screenshot or screen recording with spacing, contrast, color-token, or timing concerns.

`/art-director` activates only on explicit brand / art-direction / design-system-architecture requests, or at the start of a new product or brand refresh. Strict triage: it does NOT auto-fire on per-component or per-view design work.

## Why observation first

Skipping straight to diagnosis is how AI reviews end up validating their own assumptions. The eye-of-the-beholder skill insists on at least three concrete observations before any cause is named, so the diagnosis has to fit what is actually on screen.

The art-director skill works one level up: brand attributes and visual-language decisions captured upfront are the reference against which observations get their meaning. "Feels off" is unverifiable until there is a documented standard to feel off from.

## Installation

```bash
/plugin install eye-of-the-beholder@leclause
```
