---
name: checklist
user-invocable: false
description: >
  Internal sub-skill of the drydry plugin. Dispatched by the drydry:drydry
  orchestrator (audit mode step 2) or by another skill that needs a
  starter checklist for a new domain. Bootstraps a six-to-ten item
  duplication checklist from a domain hint plus optional operator seed
  patterns. Ships baked-in seed templates for iOS/SwiftUI, Rails,
  React/TypeScript, Markdown prose, and design tokens. Returns markdown
  the caller passes to drydry:sweep.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(ls *)
  - Bash(find *)
  - Bash(rg *)
effort: medium
---

# Checklist

The checklist bootstrapper behind the drydry audit pipeline. Builds a six-to-ten item duplication checklist for a named domain so `drydry:sweep` has an allow-list to walk (Chapter 3). Not user-invocable.

## Input contract

Caller supplies through `args`:

- **`domain`**: one of `ios-swiftui`, `rails`, `react-typescript`, `markdown-prose`, `design-tokens`, or `generic`. Maps to a baked-in seed template. Mandatory.
- **`seed_patterns`**: optional comma-separated list of additional pattern names the operator wants in the checklist (extends the seed template).
- **`scope`**: optional path; when provided, the skill briefly inspects the scope (file extensions, framework manifest, presence of typical config files) and may extend the checklist with patterns relevant to what it finds.

## Output contract

Return a markdown checklist with six to ten items. Each item has a `pattern_id`, a short title, a one-paragraph description, and one or two example signatures the sweep subagent can grep for.

```markdown
## Checklist: <domain> v<version>

### <pattern_id>: <short title>

<one-paragraph description of what the pattern looks like, why it
matters, and how it typically drifts>

Signatures to look for:
- `<grep-friendly regex or token>`
- `<another signature>`

### <pattern_id_2>: ...
```

Version the checklist with a date stamp (`v2026-05-12-1`) so the audit artefact's `## Detection method chosen` paragraph can cite it (Chapter 8).

## Seed templates (built-in)

### `ios-swiftui` (the Portier seed)

1. `confirmation-surfaces`: confirmation popovers, sheets, and dialogs solving the same destructive-action UX need with diverged copy or styling.
2. `domain-types`: parallel structs or enums modelling the same domain concept (Permit, Plate, Visitor) with subtle field-name drift.
3. `fixture-factories`: preview-helper or test-helper factories for the same domain type that diverge on defaults (timezone, derived fields, optional-vs-required).
4. `app-intents`: AppIntent perform-body boilerplate copy-pasted across intents that ought to share a helper.
5. `live-activity-sync`: Live Activity update entries built inline at multiple sites that should share a snapshot factory.
6. `presentation-modifier-stacks`: long `.sheet().alert().confirmationDialog()` chains repeated across views with minor differences.
7. `view-modifier-extensions`: custom `.modifier()` extensions duplicated across files (button styles, card containers, badge surfaces).

### `rails`

1. `service-objects`: service classes with overlapping responsibilities (UserCreator, UserOnboarder, UserRegistration) where the boundaries drift.
2. `activerecord-scopes`: parallel scopes encoding the same predicate (`active`, `enabled`, `not_archived`) across or within models.
3. `background-jobs`: ActiveJob subclasses with similar `perform` bodies, especially around retry or idempotency handling.
4. `authorisation-paths`: two ways to authorise the same endpoint (Pundit policy + before_action; cancancan + manual check).
5. `controller-actions`: actions that duplicate request-parsing or response-shaping logic that should live in a concern or a presenter.
6. `views-and-partials`: ERB partials rendering the same component with diverged class lists or content blocks.
7. `i18n-keys`: translation keys for the same user-visible string under different paths.

### `react-typescript`

1. `form-state-hooks`: custom `useFormX` hooks built around the same shape (controlled inputs, async submission, error mapping).
2. `api-client-wrappers`: thin wrappers around `fetch` or `axios` duplicated across feature folders.
3. `error-boundaries`: ErrorBoundary components with diverged retry or fallback UI.
4. `design-token-imports`: parallel imports of the same token (`tokens.color.primary` vs `palette.primary500`) hinting at a token-system split.
5. `route-guards`: HOCs or hooks that wrap routes for auth checks with diverged unauthorised behaviour.
6. `loading-and-empty-states`: skeleton or empty-state components built per-feature instead of shared.
7. `feature-flags`: client-side flag reads scattered across the tree, often with inconsistent default handling.

### `markdown-prose`

1. `duplicate-definitions`: a term defined in two places with slightly different wording.
2. `redundant-safety-paragraphs`: disclaimer, rate-limit, or auth-required notes copy-pasted across guides.
3. `repeated-examples`: the same code example or scenario reproduced verbatim or near-verbatim across pages.
4. `terms-of-art-inconsistency`: the same concept named with two terms (`tenant` vs `customer`, `user` vs `account`) within one doc set.
5. `setup-instructions`: install or first-run paragraphs repeated across guides instead of linked.
6. `versioning-notes`: per-page version markers that drift as the canonical reference moves.
7. `cross-reference-rot`: section references that no longer resolve because the target moved.

### `design-tokens`

1. `parallel-component-shapes`: two components solving the same UX need with different surface treatments (ConfirmDialog vs ConfirmSheet).
2. `spacing-token-drift`: components using ad-hoc spacing values instead of the token scale.
3. `typography-ramps`: parallel font-size scales between platforms or between teams within one design system.
4. `color-roles-vs-palette`: components using raw palette tokens instead of semantic role tokens (`color.red.500` vs `color.error.fill`).
5. `radius-and-shadow`: corner-radius and shadow values diverging across components for the same surface type.
6. `motion-curves`: parallel ease and duration values across feature areas.
7. `iconography`: two icon styles (filled vs outline) used inconsistently for the same action.

### `generic`

A fallback for projects that do not match any of the above. The seed has three placeholder patterns plus a strong nudge to the operator to extend with their own:

1. `parallel-helpers`: two helpers solving the same problem with different signatures.
2. `repeated-blocks`: structurally similar blocks across files (the Type-1 to Type-3 axis).
3. `behavioural-clones`: same-behaviour-different-structure code (Type-4, the wedge drydry lives in).

## Workflow

1. **Read `args`.** Parse `domain`, `seed_patterns`, optional `scope`.
2. **Load the seed template.** Pick the template for the domain. If `domain` is unknown, fall back to `generic` and log the unknown domain so the operator can add a seed in a follow-up.
3. **Inspect the scope (if provided).** Run `ls` on the scope, sniff a manifest (`Package.swift`, `Gemfile`, `package.json`), and add domain-specific extensions to the seed (for example: if `Gemfile` contains `devise`, add a `devise-helpers` pattern).
4. **Add operator seed patterns.** Append each item from `seed_patterns` as a new pattern entry. The seed-pattern title becomes the `pattern_id`; the description is left as a one-line stub for the operator to flesh out next time.
5. **Cap at ten.** When the combined list exceeds ten, keep the seed-template items and the operator-named items; drop the optional manifest-inferred extensions first.
6. **Stamp the version.** Format: `v<YYYY-MM-DD>-<n>` where `<n>` increments per checklist generated on the same day. Date from `date +%Y-%m-%d`.
7. **Return.** Hand back the markdown checklist to the caller.

## Rules

- **Six minimum, ten maximum.** Fewer than six is not enough breadth; more than ten dilutes the sweep.
- **Each pattern has at least one grep-friendly signature.** Without a signature the sweep subagent cannot ground the pattern. If the seed template has no signature for a pattern, write one before returning.
- **Operator seed patterns are appended, not interleaved.** The seed template order encodes "most common first"; operator additions go at the end so the priority is preserved.
- **The checklist is a snapshot, not a global state.** Every audit generates its own checklist; there is no persistent "current checklist". Reproducibility comes from logging the version in the audit artefact (Chapter 8).
