---
name: testing-philosophy
user-invocable: false
description: Use when writing tests, debugging test failures, reviewing test strategy, or making decisions about what/how to test. Covers TDD workflow, Cucumber/Gherkin conventions, flaky tests, and test suite health.
---

# Testing Philosophy

Principles and conventions for testing. The core principle: specs are specifications of expected behavior, written before the implementation exists. Not verifications after the fact. That distinction drives everything that follows.

## Specs specify, they do not verify

RSpec calls it a "spec" for a reason: it is a specification, not a test. The spec defines what "done" means before any code is written. Without that definition, "done" is a subjective judgment by the implementer. Code that compiles proves syntax. Code that passes a pre-written spec proves semantics.

**NEVER write implementation before you have seen a failing spec.**

This is not optional. This is not "where possible". This is ALWAYS, for every feature, every bugfix, and every interface change.

**Workflow:**
1. **Red**: Write spec that specifies expected behavior -> must FAIL
2. **Green**: Implement minimal code to make the spec pass
3. **Refactor**: Clean up with green specs as a safety net

**For bugfixes:**
- Write a spec that reproduces the bug (fails)
- Fix the bug (spec turns green)
- Verify by reverting the fix -> spec MUST fail again

**For interface changes (renames, columns, constructor signatures):**
- Write the spec with the new interface (fails against the old code)
- Update the implementation (spec turns green)
- "Mechanical" and "trivial" are not exemptions

**This always applies.** Even for "trivial" changes. Even for "urgent" fixes.

**One exception: purely cosmetic changes.** CSS classes, colors, spacing, font sizes, and other visual styling do not need TDD coverage. Specs that assert specific CSS classes or design tokens make the spec harness too rigid for evolving design insight. Specify behavior, not presentation.

**RED -> GREEN -> REFACTOR is a continuous flow.** Do not pause between phases to ask for permission. If the user has given an instruction ("fix dit", "pas dat aan"), run the full TDD cycle without stopping. The only pause point is AFTER the cycle, when the result is ready for review.

## Do not do more than the spec prescribes

The spec bounds the work. If there is no spec for it, it does not exist as a requirement. Want to do more? Write a new spec first. This prevents scope creep, gold plating, and the urge to "real quick" / "even snel" slip in something extra.

## UI/UX bugs get Cucumber scenarios

When a bug involves user interaction (buttons, forms, navigation, confirm dialogs, status transitions in the browser): write a Cucumber scenario, not a unit spec. Cucumber describes behavior from the user's perspective and tests the full stack including JavaScript.

Unit specs (RSpec requests, model specs) are for server-side logic. Cucumber scenarios are for everything a user sees and does.

## Gherkin scenarios are domain documentation

Feature files describe behavior in domain language, not UI interactions. They are documentation that happens to be executable.

**Declarative (good):** `When I create a todo "Buy groceries"` -> describes intent, survives UI redesigns.
**Imperative (forbidden):** `When I fill in the "title" field with "Buy groceries" And I click the "Add" button` -> breaks on every UI change, reads like a test script rather than documentation.

The UI mechanics (which field, which button, hover for hidden elements) live in step definitions, not in feature files. When the UI changes, only step definitions change. The scenarios, and with them the behavior documentation, remain stable.

**BRIEF principles:** Business language, Real data, Intention revealing, Essential, Focused, Brief (~5 lines per scenario).

## Spec scaffolding is not progress

A scenario you write out but tag as `@wip` or otherwise exclude from the suite is not a spec. It is a wish list in code format. Step definitions that only throw `PendingException` are cruft from birth.

The TDD cycle starts at Red: a spec you have never seen run red has not completed the cycle. Write a scenario, implement the steps fully, watch it turn green. Then the next scenario. Never create multiple empty scenarios at once.

Feature files that consist entirely of unimplemented scenarios should not exist. If you are not working on that feature yet, do not write a spec for it. "Setting up the structure in advance" is planning disguised as code.

## Red Flags - You are rationalizing

If you catch yourself thinking these thoughts, STOP:
- "This is too simple to specify"
- "I'll write the spec later"
- "I'm just setting up the structure in advance"
- "I'll tag it as @wip, we'll finish it later"
- "Let me first check whether it works" / "Eerst even kijken of het werkt"
- "Let me check the implementation" / "Laat me de implementatie checken"
- "The user is in a hurry"
- "It's just a rename"
- "This is a mechanical change"

-> You are rationalizing. Write the spec first.

## Spec setup guidelines

Minimize spec-level memoization/setup. Prefer local variables within the spec itself.

## Main branch is always green

Never assume a spec might fail on main. If it is on main, it passes. When verifying behavior:
- Write a spec that captures the expected behavior
- When testing a fix, apply the fix locally, run the spec, then revert the fix to see the spec fail
- Never check out main to "even checken of het op main ook faalt"
- When referencing main, always use `origin/main` since local main may be stale

## Modifying specs is forbidden

A failing spec means: fix the CODE, not the spec. Never weaken a spec to make it pass.

**Exception:** Only when requirements have actually changed, and only after explicit confirmation from the user.

## Demo is not a spec

Manual verification (demos, console output, "let me try it" / "even proberen") is not proof that code works. Demo output varies and is not deterministic.

**Forbidden:** Running an application to verify that code works.
**Required:** Automated specs with predictable input/output.

## Reading code is not a spec

Reading source code to deduce whether something works is not verification. Grepping through implementation tells you what the code does, not whether the behavior is correct from the user's perspective. When the question is "does X work?", the answer is a spec that exercises X, not a code review that concludes it should work.

**Forbidden:** `grep`/`read` through handlers and queries to conclude that a feature works.
**Required:** Write a spec that exercises the behavior from the user's side. The spec is the proof.

## Flaky specs are an investment

**Definition of flaky:** Non-deterministic specs that are sometimes green, sometimes red without a code change.

**Flaky specs are NEVER acceptable:**
- Cost every team member time across all projects
- Erode trust in the suite
- Mask real regressions
- Investing in fixing them is always the right long-term decision

**Use "flaky" ONLY for non-deterministic specs:**
- Flaky: Spec fails sometimes due to race condition, timing issue, shared state
- Not flaky: Spec always fails due to missing mock/stub
- Not flaky: Spec always fails due to external dependency (API, database)
- Not flaky: Spec always fails due to incomplete implementation

**When you encounter a flaky spec:**
1. Stop current work
2. Gather context: spec path, command to run it, error output, failure rate
3. Propose starting dedicated investigation with full context
4. Generate `claude -p` command with:
   - Spec file path and line number
   - Exact command to run the spec
   - Error output from the last failure
   - Estimated failure rate (e.g. "fails ~30% of the time")
   - Hypothesis about the cause (race condition, timing, shared state, etc.)
5. NEVER automatically try to fix it during other work
6. NEVER "retry until green" or mask flakiness

## Failing specs block everything

When the suite has failures, the only correct response is: fix them. Do not deploy, do not commit, do not say "those are pre-existing failures". Failing specs are work, just like warnings. It does not matter whether they come from your change or already existed.

**Forbidden:** Proposing to deploy or commit while the suite has failures.
**Forbidden:** Dismissing failures as "pre-existing" or "not related to my change".
**Required:** Investigate failures, fix them, and get the suite green before moving on.

**Red Flags on spec failures:**
- "Seems unrelated to my changes" -> Irrelevant. It fails. Fix it.
- "Let me verify it's pre-existing" / "Laat me verifiëren dat het pre-existing is" -> The goal is fixing, not assigning blame.
- "This is a data issue, not [my thing]" -> Categorizing is not solving.
- "Quick check whether it also fails on main" / "Even checken of het op main ook faalt" -> Even if it does, it is now your problem.
- git stash to prove it's "not yours" -> Wrong direction. Investigate the failure, not its origin.

**On CI failures that break unexpectedly:** When you discover that your changes break specs in places you did not expect, that is a signal that there may be more unexpected breakages. In that situation, run the full suite before committing the fix. Definitely do not amend a previous commit before you know the full picture is correct.

## Mass-deleting tests is a SMELL in refactors

When a refactor empties out an API, the behaviors the old tests documented still exist, just somewhere else. The tests must migrate with them, not be discarded. Concretely: do not remove a set of tests without identifying, per test case, where the behavior is now covered (another unit file, a Cucumber scenario, a Playwright script, an explicit `it.todo` with a reference). Cannot make that mapping? That is not a reason to thin, that is a blocker: the behavior is either gone without replacement (regression) or has become uncovered (gap in the safety net). A refactor diff that ends up ten lines larger is better than a test crash later. This applies even for a single test when it is the only piece of documentation for a behavior; it applies hard for any deletion pattern of more than a few cases at once.
