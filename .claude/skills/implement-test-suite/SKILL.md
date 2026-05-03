---
name: implement-test-suite
description: Use when the user wants to implement the test suite from docs/TESTS.json. Works through all open test entries sequentially, one at a time, until every entry is marked done.
---

# implement-test-suite

## Overview

Implements every open test entry from `docs/TESTS.json` — sequentially, one entry per commit, full suite green before each close.

---

## Preparation

1. Read `docs/TESTS.json` completely.
2. Filter to entries with `"status": "open"`.
3. Announce: "Starting test suite. [X] open entries: [IDs]."

---

## Test Workflow (repeat for every entry)

### Step 1 – Understand the entry
Read `id`, `name`, `description`. Summarize in 1–2 sentences: what behavior must be verified, where are the boundaries.

### Step 2 – Analyse current codebase
Locate the relevant models, controllers, services, routes. Answer: what already exists? Which test files are affected or must be created?

### Step 3 – Write tests (Red)
Place tests in the correct file based on the test pyramid (model > controller > integration > system). Create the file if it does not exist.

Every test you write must satisfy all 10 principles below — treat them as hard constraints:

| # | Principle | What it means in practice |
|---|-----------|---------------------------|
| 1 | **Test behavior, not implementation** | Assert public outcomes (return values, DB state, HTTP responses, emails sent). Never assert on private methods, internal variables, or how the code achieves its result. |
| 2 | **AAA pattern** | Every test body has exactly three logical blocks: **Arrange**, **Act**, **Assert**. Separate them with a blank line when more than two lines. |
| 3 | **One responsibility per test** | One test = one behavior. If you need `and` in the test name, split it. |
| 4 | **Determinism** | No `rand`, `Time.now`, `Date.today`, `SecureRandom` (except in fixtures where value is irrelevant). Freeze time with `travel_to` when date/time matters. |
| 5 | **Isolation** | Tests must pass in any order, any subset. Use `setup` / `teardown` or instance variables to recreate state per test. |
| 6 | **Test pyramid** | Prefer model tests > controller tests > integration tests. Add a system test only when testing a JavaScript-heavy or multi-step UI flow that cannot be covered at a lower level. |
| 7 | **Edge cases and failure paths** | For every happy-path test, write at least one test for: an invalid input, a missing required value, an unauthorized actor, or a boundary condition. |
| 8 | **Readability and intent clarity** | Test names read like documentation: `"parent cannot update another family's child"`. Use named local variables over inline literals. Prefer `assert_equal expected, actual`. |
| 9 | **Mock only external boundaries** | Stub network calls, external APIs, file uploads, and email delivery. Never mock ActiveRecord, the router, or application services unless testing the caller in isolation is essential. |
| 10 | **Fast and data-explicit** | Inline `Model.create!` in `setup` with all required attributes spelled out. Avoid loading more fixtures than necessary. Use `assert_no_difference` / `assert_difference` over re-querying when possible. |

Run the new test file — tests must **fail** or be new at this point.

### Step 4 – Make tests green
Write or fix only the minimum code necessary. Run the new file after each change. Iterate until all new tests pass.

> **Do not modify application code** to force tests green unless you discover a genuine bug. If you fix a bug, note it in the commit message.

### Step 5 – Run full suite
Run all tests. Fix any regressions introduced. Do not advance while any test is red. Confirm with actual output, not assumptions.

### Step 6 – Refine
Review the new tests critically: intent clarity, AAA compliance, determinism, isolation. Refactor where needed. Re-run the full suite — it must stay green.

### Step 7 – Close entry & commit
- Set the entry's `"status"` to `"done"` in `docs/TESTS.json`.
- Create a git commit:
  - Format: `test: [entry-id] [short entry name]`
  - Stage all relevant files (no `.env`, no secrets).
  - Append: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`
- Announce: "Entry [ID] done. All tests green. Commit created."

### Step 8 – Next entry
Return to Preparation step 2 and pick the next open entry.

---

## Completion

When all entries have `"status": "done"`, output:
- Total entries completed
- Total commits created
- Any discovered bugs fixed during implementation
- Any entries that required clarification or were skipped, with reasons

---

## Rules

| Rule | Detail |
|------|--------|
| Sequential only | Never work on two entries in parallel |
| No application changes | Tests must verify existing behavior; fix only genuine bugs |
| No bypasses | Never use `--no-verify`, never skip the full suite run |
| Ambiguous entry | If an entry's expected behavior is technically unclear → stop, document, ask for clarification |
| Unexpected failure | If an unrelated test fails unexpectedly → invoke `superpowers:systematic-debugging` before changing anything |
| Verification | Use `superpowers:verification-before-completion` before declaring an entry done |
