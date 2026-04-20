---
name: verify
description: Evidence discipline for the rover. Writes Done criteria at end of SURVEY so the mission has an actual endpoint, then gathers evidence against each criterion during INSPECT (run the code, screenshot the UI, curl the endpoint, query the state) and reports what is proven, what is still unverified, what failed. Invokable directly as /autonomous:verify on any loop file, or called by the rover during SURVEY and INSPECT.
user-invocable: true
argument-hint: "[--propose <loop-file> | <loop-file> | free text]"
---

# Autonomous Verify

Evidence discipline for autonomous work. The operator is not watching, so every claim of progress or completion has to rest on something the operator could check without being present.

Two disciplines, one skill:

1. **Write Done criteria up front.** Before the rover starts building, it commits to what "done" looks like in concrete terms.
2. **Gather evidence against those criteria.** Actively verify each criterion by running, observing, or measuring. Report what is proven, what is unverified, what failed.

## Why this matters for an autonomous rover

Without Done criteria, the rover has no endpoint. It stops when it is tired, when tests happen to be green, or when the phase machine nudges it along. None of that is "finished." The operator reading the loop file later has no way to audit whether the work actually matches the original goal.

Without active evidence, the rover coasts on proxies: "CI green," "the code compiles," "the test file exists." None of these prove the feature does what the user asked for. Proxies are the autonomous-work equivalent of driving at night without headlights.

## Mode 1: propose Done criteria (`--propose`)

Invocation: `/autonomous:verify --propose <loop-file>` or called by rover at end of SURVEY.

1. Read the loop file's `## Dispatch`, `## Context`, and `## Plan` sections. Dispatch is the source of truth; Context is interpretation; Plan is the proposed deliverable.
2. **Plan-vs-Dispatch check (mandatory).** Compare the action verbs in Dispatch against the deliverables described in Plan. If Dispatch contains action verbs (build, ship, fix, port, install, deliver, enable, make work, implement) and the Plan only describes producing research, documentation, or analysis without naming the actual implementation as the deliverable, refuse to generate Done criteria. Surface to the operator: "Plan reduces the Dispatch to research-only. Generating doc-criteria would lock in the wrong scope. Rewrite the Plan to include the implementation, or confirm explicitly that a research-only outcome is acceptable." Always compare against Dispatch, never against Context alone; Context can itself have shrunk the dispatch.
3. Derive 3 to 10 criteria. Each criterion is:
   - **Concrete:** names a specific file, command, endpoint, UI element, or observable state
   - **Observable:** you can run, see, or measure it, not just "know" it
   - **Binary:** either met or not met, not a spectrum
   - **Aligned with the Dispatch's action verbs:** if Dispatch says "make X work on Windows," at least one criterion must directly assert that X works on Windows. Doc-quality criteria alone (file exists, in Dutch, no em-dashes) do not satisfy an action-verb dispatch.
4. Write the criteria into the loop file under `## Done criteria` (create the section if missing).

### Good vs bad criteria

| Bad | Good |
|-----|------|
| "The settings page works" | "`GET /settings` returns HTTP 200 when logged in as a user" |
| "Form validation is correct" | "Submitting the form with an empty name shows an inline error next to the name field, no DB write happens" |
| "Fast enough" | "`/settings` first-paint under 200ms at p95 on the staging box" |
| "Tests pass" | "`bin/rspec spec/settings_spec.rb` exits 0 with 12 examples, 0 failures" |
| "Looks good" | "Screenshot at 1440x900 shows form below header, no horizontal scroll, no overlap with nav" |

Vague criteria are how missions drift. The rover catches this up front by insisting on sharp ones.

## Mode 2: gather evidence (default)

Invocation: `/autonomous:verify <loop-file>`, or bare `/autonomous:verify` in a session where a loop file is obvious, or called by rover at end of INSPECT.

1. Read the `## Done criteria` section.
2. For each criterion, determine the verification tactic:

| Criterion type | Tactic | Evidence |
|----------------|--------|----------|
| Code runs | Execute it (unit test, script, CLI) | Command output, exit code |
| HTTP endpoint | `curl -sSv` with expected inputs | Status code, response body |
| UI element | Navigate and screenshot | PNG path + described observation |
| UI state change | Before and after screenshots | Two PNGs, described diff |
| DB mutation | Query the DB after the action | Row count, specific field values |
| File on disk | `ls` / `stat` / `cat` | Path + relevant content |
| Third-party integration | Trigger it, inspect the other side | Log entry, API response, webhook payload |
| Logged behavior | Run, grep the log | Matched log line with timestamp |

3. For each criterion, attach the evidence under its row in the loop file. Format:

```markdown
## Done criteria

- [x] `GET /settings` returns 200 when logged in
      Evidence: `curl -s -o /dev/null -w "%{http_code}" http://app.test/settings` → 200 at 10:14
- [x] Submitting empty name shows inline error
      Evidence: screenshot `/tmp/settings-empty-name.png`, error visible next to name field
- [ ] p95 first-paint under 200ms
      Unverified: no staging box available in dev. Ran locally only: 180ms average over 5 runs.
- [ ] Tests pass
      Failed: `bin/rspec` → 12 examples, 1 failure. See log.
```

4. Report a summary:
   - Criteria met with evidence
   - Criteria unverified (why, what would be needed to verify)
   - Criteria failed (what the evidence showed, next DRIVE target)

## Mode 3: standalone use

Outside a rover session, `/autonomous:verify "free text describing the work"` lets a user ask "did I really finish what I claimed?" for any recent work. The skill:

1. Asks for or infers a short Done-criteria list from the free text and the recent diff
2. Gathers evidence
3. Reports

This is useful after any non-trivial task, not just autonomous loops.

## Proxies are not verification

The rover is tempted by proxies because they are cheaper than real evidence. Reject them:

| Proxy | Why it fails | Real verification |
|-------|--------------|-------------------|
| "CI is green" | Tests a file I cannot run | Run the relevant scenario locally |
| "The code compiles" | Syntax check, not behavior | Execute the code path |
| "The test file exists" | File existence, not passage | Run the test, see it pass |
| "Curl returns 200" | Status code, not content | Assert on response body |
| "The feature should work" | Unchecked hypothesis | Run the feature end-to-end |
| "I followed the pattern" | Pattern imitation, not correctness | Prove this instance behaves |
| "No errors in the console" | Absence is not presence | Confirm the positive outcome happened |

When a proxy is the only thing available, label it: `unverified, only proxy evidence: <X>`. Honesty beats a false green.

## When verification is genuinely impossible

Sometimes a criterion cannot be verified with available tools:

- Production-only behavior (auth, third-party services, real user load)
- Visual checks in a headless environment without a browser
- Timing-sensitive measurements without a stable baseline
- Behaviors that only manifest under rare conditions

Mark these `unverified: <specific reason>` in the Done criteria. Do not claim them met. The rover does not decide on its own that an unverified criterion is "acceptable" and push on; that decision belongs to the operator.

### Unverified is an INSPECT blocker

When INSPECT runs, any criterion still marked `unverified` blocks the transition to STOW. The rover's only two legitimate moves at this point are:

1. **Find an alternative verification route.** If the direct evidence is out of reach, what proxy is at least partly informative, and can it be upgraded by running additional commands, spawning a subagent against a different environment, or instrumenting the code? Log the attempt explicitly. "I could not run the staging test" is not acceptable until "I tried A, B, and C, and here is why each failed" has been logged.
2. **Surface the blocker to the operator via `## Input`.** Write a one-paragraph note in the loop file naming the criterion, explaining what was attempted, and asking for either a decision to accept, a path to verify, or a scope removal. Stay in INSPECT until the operator has replied.

The rover **never** upgrades `unverified` to a tick on its own, never silently drops a criterion from the list, and never reasons "in de praktijk zal dit wel werken" to close it out. Those moves are the exact corner-cutting this discipline exists to prevent. If you catch yourself typing "accepting unverified" or "acceptable given context" into the loop file without an operator response, revert and surface instead.

## Anti-patterns

| Thought | What it actually is |
|---------|---------------------|
| "I'll verify at the end" | No you will not, you will run out of steam. Verify per change. |
| "This is too obvious to verify" | Obvious things fail too. 30 seconds of evidence beats 5 minutes of debugging later. |
| "Verification would take forever" | If verifying the mission takes longer than doing it, the mission is probably too big. Split. |
| "The tests cover it" | Tests are a form of verification, but rarely the full criterion. What did the user see? |
| "I already checked" | Show the evidence. If you cannot cite it, you did not check. |

## Interaction with other skills

- **`decide`** picks which path to take; `verify` proves the chosen path worked. Complementary.
- **`pride`** asks "would the user hate this?" (contrarian, smell-finding); `verify` asks "did this do the thing?" (evidence-gathering). Different questions, no overlap. The rover runs both before declaring done.
- **`rover`** invokes `verify --propose` at end of SURVEY and `verify` (default) at end of INSPECT. A rover mission without Done criteria is not started; a rover mission without ticked criteria is not finished.
