---
name: add-to-mandje
description: >-
  One-shot single-item add to the Picnic mandje (the operator's running Picnic order). Use when the operator names a specific product they want bij their next Picnic delivery, without walking an AnyList list. Dictation-friendly trigger phrases (Dutch, spoken or written): "kun je X aan mijn bestelling in Picnic toevoegen", "voeg X toe aan mijn Picnic mandje", "doe X bij de Picnic", "X erbij in Picnic", "X bij de boodschappen", "Picnic-mandje X erbij", "zet X in mijn Picnic order", and every equivalent that names a single product plus the Picnic brand. The Dutch word for an outdoor meal on a blanket is "picknick" (two k's); that is not this skill. The Picnic brand is one k, capitalised, refers to picnic.app, reached via the `groceries` Ruby CLI in this repo. This skill is the single-item counterpart of `order-from-anylist`, which walks the entire AnyList Boodschappen list; use this one when the operator names a single specific item, use that one when they want a full triage.
user-invocable: true
---

# Add to mandje

Single-item add to the Picnic mandje. The operator names ONE product (e.g. "doe een halfvolle melk bij mijn Picnic", "kun je avocados aan mijn bestelling toevoegen") and you find it, confirm the match, and post it to `cart/add_product` via the gem CLI. No AnyList interaction.

## Tooling

- The CLI is the `groceries` gem in this repo, invoked as `groceries-cli/bin/groceries` from the kassa repo root. Claude Code always runs from that root, so every command below is written relative to it. There is no PATH command and no wrapper script.
- The gem reads its own credentials from `super-secret` (macOS Keychain) via its `Secrets` layer, and on login/2FA stores the fresh token back into the keychain itself.
- All commands are issued by Claude via the Bash tool from the kassa repo root. The operator does not run them by hand.
- Never `super-secret get` from this skill; the gem handles every read. Never echo a credential.

## Procedure

### 1. Extract the search query

Pull the product name from the dictation. Drop filler words ("kun je", "aan mijn", "voor de Picnic", "in mijn mandje"). Examples:

- "Kun je halfvolle melk aan mijn bestelling in Picnic toevoegen?" → query = "halfvolle melk"
- "Doe een paar avocados bij de Picnic" → query = "avocado", count hint = 2-3
- "Zout erbij in Picnic" → query = "zout"
- "Verse spaghetti voor 2 personen bij de Picnic" → query = "verse spaghetti", count hint = depends on pack size

### 2. Confirmation that Picnic auth is fresh

Run a cheap auth-check via `groceries-cli/bin/groceries picnic search "<query>" --json --limit 5`. If it returns 403 Forbidden, route through the 2FA flow before continuing:

```bash
groceries-cli/bin/groceries picnic 2fa generate              # default SMS, override with --channel EMAIL or VOICE
# ask the operator for the six-digit code
groceries-cli/bin/groceries picnic 2fa verify NNNNNN         # gem stores the post-2FA token in the keychain
```

Then retry the search.

### 3. Pick the Picnic product

The search returns up to 5 selling units. Pick the best match using:

- **Exact name match** wins (e.g. "halfvolle melk" → `Halfvolle melk` over `Magere melk`)
- **Brand preference** if the operator named one (e.g. "Campina yoghurt" → prefer Campina SKU)
- **Pack size sanity**, for fresh produce 1× the smallest unit; for staples (rice, pasta, flour) pick the pack the operator typically uses (single-pack default; count is set in stap 4)

When 2 or more hits are equally plausible, route through `AskUserQuestion` with one question listing the top 2-4 candidates (label = `Brand product unit_quantity €price`, description = optional notes like "biologisch" or "kleinste pack"). Add a `Skip` option for "geen goede match, voeg niets toe".

### 4. Confirm + count

Show the operator the chosen product as a one-line Markdown summary:

```
| Picnic product | Hoeveelheid | × | Totaal hoeveelheid | Prijs |
|---|---|---|---|---|
| Halfvolle melk | 1 liter | 1 | 1 liter | €1.19 |
```

Then ask via `AskUserQuestion` whether to add. Options:

- `Go — add 1 to mandje` (default)
- `Add 2` (when the unit_quantity is small or the operator hinted at multiple in the dictation)
- `Skip — andere match` (lets the operator name another search query)

When the dictation already named a count ("doe twee paprika bij de Picnic"), default to that count in the summary and let `Go` confirm it.

### 5. Execute

```bash
groceries-cli/bin/groceries picnic cart add <product_id> --count <count>
```

The gem POSTs `cart/add_product` to Picnic. Report the one-line confirmation:

```
toegevoegd aan Picnic mandje: <picnic_product_name> × <count>
```

If the operator is dictating via Telegram (graham), keep the confirmation under 2 sentences so it reads well in a notification.

## Notes

- This skill does not touch AnyList. The item the operator named does NOT get check-off treatment because there is no corresponding AnyList list-item context. If the operator wants the item ALSO on their AnyList list, that is a separate dictation ("zet X ook op de boodschappenlijst") that would route through a different skill.
- Run every command from the kassa repo root (where Claude Code starts); `groceries-cli/bin/groceries` resolves its own `lib/` regardless of cwd.
- Never echo a credential. The gem reads the keychain itself via the `Secrets` layer.
- For multi-item additions ("kun je melk, brood en yoghurt bij de Picnic doen"), call this skill once per item; collect the confirmations and present them as one combined summary. Do not loop the operator through 3 separate AskUserQuestion ceremonies if the matches are unambiguous.

## When to escalate to order-from-anylist

If the operator's dictation references the AnyList list ("doe de boodschappen", "Picnic mandje vullen vanuit Boodschappen", "haal de boodschappen op"), this is the wrong skill. Hand off to `order-from-anylist`. Hint phrases that signal a list-walk: "boodschappen", "Boodschappen-lijst", "weekboodschappen", "alle items van AnyList". One-item dictations stay here.
