---
name: order-from-anylist
description: LLM-assisted triage flow that walks the WHOLE AnyList shopping list (default "Boodschappen"), classifies each unchecked item, picks a Picnic product per item via catalog search, waits for operator approval, then executes the dual-write to the Picnic mandje plus AnyList check-off. Trigger only when the operator's dictation references the AnyList list or the full weekly groceries cycle, not when they name a single product. Concrete trigger phrases (dictation-friendly, both written and spoken): "doe de boodschappen", "doe de boodschappen-triage", "Picnic mandje vullen", "vul mijn Picnic mandje vanuit AnyList", "Boodschappen-lijst naar Picnic", "AnyList in Picnic", "AnyList-to-Picnic", "weekboodschappen via Picnic", "haal de boodschappen op", "Picnic-order maken vanuit de lijst", "bestel de boodschappen". Single-item dictations like "kun je X aan mijn bestelling in Picnic toevoegen" or "doe X bij de Picnic" route to the sibling skill `add-to-mandje` instead, which adds one product without touching AnyList. The Dutch word for an outdoor meal on a blanket is "picknick" (two k's); that has nothing to do with this skill and should never trigger it. The Picnic brand is one k, capitalised, refers to the Dutch online supermarkt picnic.app, and is reached via the `groceries` Ruby CLI in this repo.
user-invocable: true
---

# Order from AnyList

End-to-end triage flow from an AnyList shopping list (default "Boodschappen") to the Picnic mandje. The operator types `/groceries:order-from-anylist` (or a natural-language equivalent like "doe de boodschappen-triage", "haal de boodschappen op", "Picnic mandje vullen"); Claude runs the CLI, classifies each item, proposes a plan, waits for operator approval, then executes the dual-write.

## Tooling

- The CLI is the `groceries` gem in this repo, invoked as `groceries-cli/bin/groceries` from the kassa repo root. Claude Code always runs from that root, so every command below is written relative to it. There is no PATH command and no wrapper script.
- The gem reads its own credentials from `super-secret` (macOS Keychain) via its `Secrets` layer, and on login/2FA it stores the fresh token back into the keychain itself. Nothing external sets env vars or persists tokens.
- All commands below are issued by Claude via the Bash tool from the kassa repo root. The operator does not run them by hand.
- Credentials live in keychain under `picnic-app-*` and `anylist-app-*`. Never `super-secret get` from this skill; the gem handles every read. Never echo a credential.

## Procedure

The flow is eight steps. Skip nothing.

### 1. Confirm reachability

```bash
groceries-cli/bin/groceries anylist lists
```

The expected list `Boodschappen` should appear in the output. If `groceries-cli/bin/groceries anylist lists` fails with `Missing ANYLIST_ACCESS_TOKEN`, run `groceries-cli/bin/groceries anylist login` first (the gem stores the fresh token in the keychain itself). If the list name has changed (`Boodschappen` is the working assumption; the operator names another list if they want), ask the operator which list before proceeding.

If a Picnic call returns `403 Forbidden`, the Picnic session needs the two-factor verification flow. Run `groceries-cli/bin/groceries picnic 2fa generate` (default channel SMS, override with `--channel EMAIL` or `--channel VOICE`), ask the operator for the six-digit code that just arrived, then `groceries-cli/bin/groceries picnic 2fa verify NNNNNN`. The gem stores the post-2FA token in the keychain under `picnic-app-auth-token`. After that, retry the call that failed. Skip this step on first run; it only fires when Picnic invalidates the session and demands a fresh 2FA round.

### 2. Read unchecked items as JSON

```bash
groceries-cli/bin/groceries anylist items "Boodschappen" --unchecked --json
```

Each item carries `id, name, quantity, details, category, checked, recipe_id, raw_ingredient`. The `recipe_id` and `raw_ingredient` fields signal whether an item came from a recipe import (use them to classify ambiguous ones).

### 3. Pull historical Picnic deliveries once

```bash
groceries-cli/bin/groceries picnic deliveries --json --limit 15
```

This is the **primary anti-push signal**, not just a tiebreaker. Picnic's search ranking promotes house-brand and inkoop-incentive SKUs to the top; the operator's own repeat purchases reveal which SKU they actually trust for a concept (e.g. "havermelk" recurring as Oatly haverdrink barista, "yoghurt zonder lactose" as Arla Griekse stijl lactosevrij). **Match history-first**: if the operator structurally buys a SKU for a concept and it fits the constraint, pick it over whatever the search ranks first. History-first is how you resist the push. Build a compact frequency map once (product_id, name, unit_quantity, in how many deliveries it appears) and reuse it for every item.

History tells you WHICH SKU and WHICH variant (ongezoet vs gezoet, barista vs gewoon), never HOW MANY. The frequency count is deliveries-over-time, NOT a per-order quantity: a SKU bought in 10 separate deliveries still means count 1 this order unless the list says otherwise. Deriving count from frequency is a classic error (it once bumped chili-olie to 2 on its own). Count comes from the list and dedup (stap 4) and the operator review (stap 6), never from history frequency.

### 4. Cluster, classify, and match

**First cluster the unchecked items by product concept.** Duplicate or near-duplicate entries (`komkommer` and `Komkommer ` with a trailing space, `Vega Kip stukjes` and `Vegan kipstukjes`) are the same concept and get ONE pick. Keep genuinely different forms apart, though: verse `Tomaat`/`Tomaten` is not `Tomatenblokjes` (blik). The number of list entries in a cluster is a *demand* signal (two recipes each wanting cucumber), but a near-identical duplicate can equally be list-hygiene noise; propose a count and let the operator confirm in stap 6.

**Normalize the search term to the core concept.** Strip ruis-qualifiers that rode in from a Picnic recipe import: `Bio limoenen pitloos` -> search `limoen`. The operator does not care about `bio`/`pitloos`/brand unless they typed it themselves in the `details` field. A qualifier in `details` (e.g. `Vegan`) IS a hard constraint; a qualifier baked into the recipe-imported `name` is noise.

For each cluster, decide one of four verdicts:

- **add**: a real grocery we order at Picnic. Match a product (rules below).
- **skip-not-grocery**: a Siri-captured reminder or task (`Tandarts afspraak maken`, `Verzekeringen uitpluizen`, `Broeken voor Florian`, `AH Bonus`, `Plan maken huis verhuren`). Do NOT add, do NOT check off; it stays as the operator's reminder.
- **not-picnic**: a real grocery-ish item the operator buys elsewhere, or that Picnic does not carry in the requested form (`Wasbare boterhamzakjes` -- Picnic only has disposable). Do NOT silently substitute a wrong-concept product; surface it as an operator question (skip / accept substitute / elsewhere).
- **ambiguous**: real signal, unclear which product (`Sla` without a variety). Ask at stap 6.

**Matching rules (for add-verdicts):**

1. **History-first.** Check the deliveries frequency map first. If the operator structurally buys a SKU for this concept and it fits the constraint, that is the pick -- it beats the search top-hit and resists the Picnic push.
2. Search the catalog: `groceries-cli/bin/groceries picnic search "<genormaliseerde term>" --json --limit 8`. Try 2-3 query variants when the first is thin.
3. Respect the hard `details` constraint (`Vegan` -> no dairy; the household is lactosevrij, so default plantaardig/lactosevrij when in doubt). **When no product satisfies a hard constraint, ASK** -- do not substitute a constraint-violating or concept-changing product on your own (there is no vegan creme fraiche at Picnic; ask rather than quietly picking neutral oat cooking cream). Beware the operator's typed constraint may be looser than literal: "Vegan" creme fraiche turned out to mean "lactosevrij is fine" -- which made the trusted Arla lactosevrij the right pick once asked.
4. **Fresh over frozen, in season.** For produce prefer fresh; never default to diepvries for soft fruit (aardbeien) unless the operator asked. The current date drives the seasonality call.
5. **Resist the push.** Distrust a house-brand or pricier SKU as top-hit when a cheaper or operator-trusted alternative covers the concept just as well. But history-first wins over raw cheapest: when the operator structurally buys a brand (Go-Tan, Santa Maria, Lavazza), keep it even if a cheaper Picnic house-brand exists.
6. **Reconcile count against pack size.** A proposed "2 avocado's" mapped to an `Avocado eetrijp (2 stuks)` SKU is count 1, not 2 -- the pack already holds two. Only multiply when each unit is a single item.
7. `display_price` is in cents.

Note `product_id, name, unit_quantity, display_price`, the `count`, and which `anylist_item_id`(s) the cluster covers. For a long list, running the match plus a skeptical second pass per concept (is this a Picnic-push? fresh-not-frozen? does it respect the `details` constraint? is the count sane against pack size?) catches the wrong-variant and frozen-instead-of-fresh mistakes a single pass misses.

### 5. Per add-verdict: write to the plan

```bash
groceries-cli/bin/groceries plan add <anylist_item_id> <picnic.product_id> \
  --list "Boodschappen" \
  --anylist-name "<item.name>" \
  --picnic-name "<picnic.name>" \
  --picnic-unit-quantity "<picnic.unit_quantity>" \
  --picnic-display-price <picnic.display_price> \
  --count <inferred_count>
```

`--picnic-unit-quantity` is optional (variable-weight Picnic products return blank); pass `""` if the JSON gave an empty string.

Run one `plan add` per add-verdict. The plan-file (default `/tmp/groceries-plan.json`, override via `GROCERIES_PLAN_PATH`) overwrites by `anylist_item_id`, so re-running an `add` with corrected count is safe.

**Deduped clusters covering multiple list items.** The plan keys one entry per `anylist_item_id` and adds `count` units per entry; it cannot yet bundle several list items under one cart-add. So:

- Cluster total equals the number of list entries (komkommer x2 from two entries): stage one `plan add` per `anylist_item_id` with `--count 1`. Each entry adds one unit and checks off its own list item. Same product_id across entries is fine -- the Picnic cart merges them into one line.
- Cluster total is *fewer* than the list entries (two `Koriander` entries but you only want one bunch; `Creme fraiche` + `Haver fraiche` both meaning one tub): stage ONE `plan add` for one `anylist_item_id`, and check off the remaining duplicate ids by hand right after execute with `groceries-cli/bin/groceries anylist check "Boodschappen" <id>`. These are approved groceries being merged, so checking them off is correct -- the "never check unapproved" rule (Notes) is about non-groceries, not merged duplicates.

### 6. Present the plan

```bash
groceries-cli/bin/groceries plan show
```

Print the output verbatim to the operator. Then for every item flagged as **ambiguous** in step 4, route the decision through the `AskUserQuestion` tool instead of free-form prose. One question per ambiguous item, each with 2-4 concrete options derived from the Picnic search hits (or a literal `Skip` option when no usable hit). Batch up to four ambiguous items per `AskUserQuestion` call. For each option, include the Picnic product id, unit_quantity, and display_price in the `description` so the operator can pick at a glance. Open-ended cases (e.g. "Fruit" without a specific variant) get a question with `Skip` plus 1-2 likely candidates; the operator's free-text "Other" answer is the fallback signal to run a fresh search with their query.

After the questions are answered: `plan add` every approved ambiguous item, then re-run `groceries-cli/bin/groceries plan show` so the table reflects the final picks. Also surface the `skip-not-grocery:` items as a short bullet list in the same response so the operator can spot misclassifications.

Before asking the execute-question in stap 7, render the final plan as a Markdown table (columns: #, AnyList item, Picnic product, Hoeveelheid, ×, **Totaal hoeveelheid**, Prijs, met `totaal` op de laatste regel). The monospace output van `plan show` is alleen voor jouw interne check; de operator ziet de Markdown-tabel die vervolgens in de TUI als nette tabel wordt gerenderd. Zonder die tabel-rendering is de execute-keuze te abstract om er ja op te zeggen.

De **Totaal hoeveelheid** kolom is de count × unit_quantity (bv `1 × 250 gram = 250 gram`, `2 × 1 stuk = 2 stuks`). Die kolom is de eigenlijke count-review moment voor de operator: bij elk item kunnen ze op één blik zien dat 250 gram pasta krijgen terwijl ze 500 gram wilden, en zeggen "spaghetti naar 2". Jij doet daarop `plan add` met dezelfde anylist_item_id en de nieuwe count (last-wins), hertekent de tabel, vraagt opnieuw om go.

The interactive-menu route exists because free-form questions ("Bedoel je X of Y?") in a chat thread force the operator to copy-paste names and answer one at a time, which loses the at-a-glance picnic-product context. `AskUserQuestion` keeps the choices structured and machine-trackable.

### 7. Wait for operator go

The operator says go, ship it, doe maar, yolo, or equivalent. They might also edit:

- `groceries-cli/bin/groceries plan remove <anylist_item_id>` to drop an entry.
- A correction to an `add` is just another `groceries-cli/bin/groceries plan add` with the same `anylist_item_id` (last-wins).
- `groceries-cli/bin/groceries plan clear` to wipe and restart.

If the operator says no or wants to think first, leave the plan-file as-is; it survives across CLI invocations within the same session.

### 8. Execute

```bash
groceries-cli/bin/groceries plan execute
```

This walks each entry. Per entry: post `cart/add_product` to Picnic, then `set-list-item-checked y` on the AnyList list. The command prints one line per entry with one of three statuses:

- `klaar` -> cart added and AnyList checked off.
- `half` -> cart added but AnyList check faalde; the entry leaves the plan and the operator must check that item off in AnyList by hand.
- `fout` -> cart add faalde; the entry stays in the plan for a retry.

On full success (every entry `klaar`) the plan-file is wiped. The closing `samenvatting:` line reports the counts plus the euro total that landed in Picnic.

Right after `plan execute`, run any deferred check-offs from the merge-handling in stap 5 (`groceries-cli/bin/groceries anylist check "Boodschappen" <id>` for the duplicate list items you folded into one product), and add any not-on-the-list afterthoughts (see Notes) with `groceries-cli/bin/groceries picnic cart add`.

Final step: relay the `samenvatting:` line plus any `half`/`fout` entries to the operator ("Picnic mandje gevuld met N items voor €X.YZ; M items afgestreept in AnyList. K items als skip-not-grocery laten staan voor je herinnering. P items half (handmatig afvinken: <namen>). Q items fout (blijft in plan: <namen>)."). Verify the real mandje with `groceries-cli/bin/groceries picnic cart show` (total_count, total_price) and report that as the authoritative total; it can differ from the plan total by a few cents when a live price moved since the search. Operator does the actual checkout in the Picnic iPhone app.

## Notes

- Run every command from the kassa repo root (where Claude Code starts). `groceries-cli/bin/groceries` resolves its own `lib/` regardless of the caller's cwd, so no `cd` into the silo is needed.
- Plan-file lives at `/tmp/groceries-plan.json` (override via `GROCERIES_PLAN_PATH` env var if needed). macOS wipes /tmp on reboot, so a triage started in the evening and not executed before reboot is lost; the operator runs the skill again to rebuild it.
- If the operator runs the skill mid-flow and a plan-file already exists, `groceries-cli/bin/groceries plan show` it first. They might have left a partially-executed plan from an earlier session.
- Never echo a credential. The gem reads the keychain itself via the `Secrets` layer. If you ever catch yourself about to write `super-secret get` in a Bash invocation, stop: that path leaks the value into the conversation transcript.
- Read-only on AnyList for skip-not-grocery items. Never `groceries-cli/bin/groceries anylist check` an item the operator did not approve as `add`. AnyList is the operator's source of truth for "what we still need"; respect it.
- **The Boodschappen list is the source of truth for quantities, not the recipes.** AnyList already matches meal-planner recipe ingredients onto the shopping list precisely when the operator checks them off; the recipes carry no better quantity info than the list. Do not reconstruct demand from the recipe calendar (`anylist recipes`, the meal-planner) -- work from the list, and treat duplicate entries (stap 4) as the demand signal.
- **Flag a much cheaper identical-name SKU.** When the trusted SKU and a same-name same-size SKU differ by more than ~2x (seen with `Picnic tomatenblokjes 400g` at EUR1.19 vs EUR0.49), it may be a relisting/reprice of the same product or a different line with a colliding name. You cannot prove identity, so surface it as an operator question rather than silently keeping the pricier history SKU or silently switching.
- **Adding a product that is not on the AnyList list** (an operator afterthought mid-flow, "doe er ook een blok belegen kaas bij"): there is no `anylist_item_id` to check off, so it does not go through the plan. Search it, then add it straight to the mandje with `groceries-cli/bin/groceries picnic cart add <product_id> --count <n>` as part of the execute step, and include it in the closing summary.

## When to ask the operator

Asking is fine before executing. Never ask while iterating through items, just collect ambiguous-verdicts and present them once at step 6. Specifically:

- Before step 8 always: "Akkoord met dit plan?"
- At step 6 for each ambiguous item: one targeted question with the candidate it most resembles.
- At step 6 for `not-picnic` items: skip, accept a disposable/substitute, or buy elsewhere.
- At step 6 when a hard `details` constraint has no satisfying product: which substitution, or skip.
- At step 6 when a same-name SKU is much cheaper than the trusted one: which SKU.
- Counts that came from duplicate list entries: propose a number, but let the operator confirm in the stap 6 review (the **Totaal hoeveelheid** column is that moment).
- Step 1 only if `Boodschappen` does not exist by that name; otherwise default to it.
