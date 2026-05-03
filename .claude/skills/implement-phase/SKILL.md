---
name: implement-phase
description: Use when the user wants to implement a specific development phase from docs/TASKS.json. Triggered by phase number parameter. Works through all open tasks in the phase sequentially, respecting dependencies.
---

# implement-phase

## Overview

Implements all open tasks of a given phase from `docs/TASKS.json` – sequentially, test-first, with browser validation and git commit per task.

**Parameter:** `phase` – the phase number to implement (e.g. `/implement-phase 1`)

---

## Preparation

1. Read `docs/TASKS.json` completely.
2. Find the phase matching the `phase` parameter → read its `feature_ids` array.
3. Filter to tasks with `"status": "open"` in that phase.
4. Build an ordered task list respecting the `feature_ids` sequence.
5. Respect `dependencies`: a task may only start when all listed dependency IDs have `"status": "done"`.
6. Announce: "Starting Phase [N] – [phase name]. [X] open tasks: [IDs]."

---

## Task Workflow (repeat for every task)

### Step 1 – Understand the task
Read `id`, `name`, `description`, `acceptance_criteria`, `test_scenarios`, `success_criteria`. Summarize in 2–3 sentences: what must be built, where are the boundaries.

### Step 2 – Analyse current codebase
Inspect relevant models, controllers, views, config, tests. Answer: what already exists, what is missing, where will changes be made? Verify no existing functionality will break.

### Step 3 – UI tasks: invoke mikiwa-design skill
If the task touches views, layouts, forms, email templates, or any visual output → **invoke `mikiwa-design` skill BEFORE writing any UI code**. Its guidelines are binding.

### Step 4 – Write tests first (Red)
Write unit specs (RSpec model/service) AND system specs (RSpec/Capybara) covering every `test_scenarios` entry and all `acceptance_criteria`. Run tests – they must **fail** at this point. Document which spec files were created.

### Step 5 – Implement (Green)
Write migrations, models, controllers, views, services, jobs, mailers, routes, config – whatever is needed. Follow Rails conventions and existing architecture patterns. Run the test suite after each significant change. Iterate until **all tests are green** and all `success_criteria` are met. Security rules apply: no SQL injection, no XSS, no CSRF gaps.

### Step 6 – Browser validation
If the task has UI or user flows: start the dev server and open the relevant pages. Check: responsive layout at 375 px, touch targets ≥ 44 px, correct branding, functional interactions. Test the golden path and key edge cases. If browser validation is impossible, document why – never skip silently.

### Step 7 – Code review & refactoring
Review new code critically: duplication, unnecessary complexity, Rails-convention violations, security issues. Refactor where needed. Re-run **all** tests – they must stay green. Confirm with actual test output, not assumptions.

### Step 8 – Close task & commit
- Set task status in `docs/TASKS.json` to `"status": "done"`.
- Create a git commit:
  - Message format: `feat: [Task-ID] [short task name] – [what was implemented]`
  - Stage all relevant files (no `.env`, no secrets).
  - Append: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`
- Announce: "Task [ID] done. All tests green. Commit created."

### Step 9 – Select next task
Check which tasks are now unlocked (dependencies satisfied). Pick the next open task → repeat from Step 1.

---

## Phase Completion

When all tasks in the phase have `"status": "done"`, output a summary:
- Phase name and number
- List of completed task IDs with names
- Total commits created
- Any open issues or follow-ups noted during implementation

---

## Rules

| Rule | Detail |
|------|--------|
| Sequential only | Never work on two tasks in parallel |
| Test-first always | No production code before a failing test exists |
| No bypasses | Never use `--no-verify`, never skip security checks |
| Dependency order | Blocked tasks wait; announce which tasks are waiting and why |
| Debugging | If a test fails unexpectedly → invoke `superpowers:systematic-debugging` before changing implementation |
| Unclear criteria | If an acceptance criterion is technically impossible → stop, document, ask for clarification |
| Verification | Use `superpowers:verification-before-completion` before declaring a task done |
