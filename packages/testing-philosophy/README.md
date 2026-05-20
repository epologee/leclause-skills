# testing-philosophy

Opinionated testing guide. Covers Red-Green-Refactor TDD workflow, end-to-end behaviour-test conventions (Cucumber/Gherkin and other framework choices), flaky test diagnosis, and overall test suite health. Loads automatically when test work is in progress; not user-invocable on its own.

## What it covers

- **TDD workflow.** Red first, then green, then refactor. The spec is a specification of expected behavior, not a verification of existing code. Renames, column changes, and constructor changes are interface changes and start with a failing spec, not a refactor.
- **End-to-end behaviour tests.** Project-framework choice (Cucumber, Playwright, Cypress, XCUITest, RSpec system specs, whichever the project uses); feature-file or scenario conventions for Gherkin-style runners (Given/When/Then phrasing, step definitions, scenario outlines); where to draw the line between unit, integration, and feature tests.
- **Flaky tests.** Diagnose root cause rather than retry-loop them. Time, order, shared state, and external service flake are the usual suspects.
- **Suite health.** Red tests are an active blocker, regardless of who broke them. A codebase with red tests has no safety net for the next change.

## Auto-trigger

Activates when:

- writing or modifying tests
- debugging a test failure
- reviewing a test strategy
- making decisions about what or how to test

Not invocable as a slash command. The plugin loads its guidance into the conversation when the relevant work appears.

## Installation

```bash
/plugin install testing-philosophy@leclause
```
