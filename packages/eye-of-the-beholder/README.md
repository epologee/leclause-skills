# eye-of-the-beholder

Visual layout review. Observation before explanation: screenshot first, describe what you see, then diagnose. Design-TDD for CSS.

Catches cramped text, missing margins, disproportionate spacing, broken WCAG contrast, ad-hoc token use, snapping transitions, out-of-sync animations, and content that disappears before its container does.

## Commands

### `/eye-of-the-beholder`

Reviews the current visual state. Captures a screenshot, lists concrete observations, then maps each observation to a diagnosis (token, spacing scale, contrast ratio, animation timing).

## Auto-trigger

Activates DURING and AFTER layout CSS, color token, contrast, or animation work. Also activates when the user shares a screenshot or screen recording with spacing, contrast, color-token, or timing concerns.

## Why observation first

Skipping straight to diagnosis is how AI reviews end up validating their own assumptions. The skill insists on at least three concrete observations before any cause is named, so the diagnosis has to fit what is actually on screen.

## Installation

```bash
/plugin install eye-of-the-beholder@leclause
```
