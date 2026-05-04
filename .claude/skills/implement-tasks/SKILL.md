---
name: implement-tasks
description: Use when the user wants to implement all open tasks from docs/TASKS.json across all phases. Works through every task with status "open" sequentially, respecting dependencies and phase order. Reads optional spec_file references for deeper specifications before implementation.
---

# implement-tasks

## Overview

Implements **all open tasks** from `docs/TASKS.json` – sequentially, test-first, with browser validation and a git commit per task. No phase parameter required: every task with `"status": "open"` is in scope, regardless of phase.

If a task references a deeper specification via the optional `spec_file` attribute, that spec **must** be read and analysed before implementation begins.

**Parameter:** none.

---

## Preparation

1. Read `docs/TASKS.json` completely.
2. Collect every feature where `"status": "open"`.
3. Build an ordered task list:
   - Outer order follows `implementation_phases` (phase 1 → 6 …) – this is the recommended sequence.
   - Inner order follows the `feature_ids` array of each phase.
   - Tasks in higher phases wait until lower phases are clear, except when a dependency arrangement forces otherwise.
4. Respect `dependencies`: a task may only start when **every** listed dependency ID has `"status": "done"`. If a dependency is still open, defer the task and pick the next eligible one.
5. Announce: "Starting open-task run. [X] open tasks across phases [list]: [IDs]. First up: [ID] – [name]."

If no open tasks exist, stop and report "Keine offenen Tasks in docs/TASKS.json."

---

## Task Workflow (repeat for every open task)

### Step 1 – Understand the task
Read `id`, `name`, `description`, `acceptance_criteria`, `test_scenarios`, `success_criteria`, `dependencies`, and `spec_file` (if present). Summarize in 2–3 sentences: what must be built, where the boundaries are, which phase it belongs to.

### Step 2 – Read the spec file (if present)
If the task has a `spec_file` attribute:
- Open the referenced file (relative to repo root).
- Read it **completely** – not just the summary.
- Extract: problem statement, goals/non-goals, technical approach, edge cases, acceptance details, open questions.
- Reconcile with the task's `acceptance_criteria` / `test_scenarios`. If the spec contradicts or expands the task, **the spec wins** for technical detail; the task's success_criteria remain the gate.
- Document a 3–5 bullet summary of what the spec adds beyond the task entry before continuing.

If the `spec_file` path does not exist or cannot be parsed → stop and ask for clarification. Never silently skip a referenced spec.

### Step 3 – Analyse current codebase
Inspect relevant models, controllers, views, config, tests, migrations. Answer: what already exists, what is missing, where will changes be made? Verify no existing functionality will break. For tasks in late phases, check whether earlier-phase code matches assumptions.

### Step 4 – UI tasks: invoke mikiwa-design skill
If the task touches views, layouts, forms, email templates, mailer styles, or any visual output → **invoke `mikiwa-design` skill BEFORE writing any UI code**. Its guidelines are binding.

### Step 5 – Write tests first (Red)
Write unit specs (Minitest model/service) AND system/controller specs covering every `test_scenarios` entry and all `acceptance_criteria` (including spec-file additions from Step 2). Run tests – they must **fail** at this point. Document which test files were created or extended. If unsure how to write a test, invoke `write-test` skill.

### Step 6 – Implement (Green)
Write migrations, models, controllers, views, services, jobs, mailers, routes, config – whatever is needed. Follow Rails conventions and existing architecture patterns. Run the test suite after each significant change. Iterate until **all tests are green** and all `success_criteria` (task + spec) are met. Security rules apply: no SQL injection, no XSS, no CSRF gaps, Pundit policies enforced where relevant.

### Step 7 – Browser validation
If the task has UI or user flows: start the dev server and open the relevant pages. Check: responsive layout at 375 px, touch targets ≥ 44 px, correct branding, functional interactions. Test the golden path and key edge cases. If browser validation is impossible, document why – never skip silently.

### Step 8 – Code review & refactoring
Review new code critically: duplication, unnecessary complexity, Rails-convention violations, security issues, missing Pundit checks, N+1 queries. Refactor where needed. Re-run **all** tests – they must stay green. Confirm with actual test output, not assumptions. Use `superpowers:verification-before-completion` before declaring done.

### Step 9 – Close task & commit
- Set the task's `status` in `docs/TASKS.json` to `"done"`.
- Create a git commit:
  - Message format: `feat: [Task-ID] [short task name] – [what was implemented]`
    (use `fix:` for bugfix tasks like `BF-xxx`).
  - Stage all relevant files (no `.env`, no secrets, no unrelated changes).
  - Append: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`
- Announce: "Task [ID] done. All tests green. Commit created."

### Step 10 – Select next task
Recompute the eligible-task list:
- Re-read `docs/TASKS.json` if it may have been edited externally.
- Determine which previously-blocked tasks are now unlocked (dependencies satisfied).
- Pick the next open task in the established order → repeat from Step 1.

---

## Run Completion

When no task with `"status": "open"` remains, output a final summary:
- Total tasks completed in this run, grouped by phase.
- List of completed task IDs with names.
- Total commits created.
- Any open issues, deferred decisions, or follow-ups noted during implementation (e.g. spec questions raised, tests skipped with reason).

---

## Rules

| Rule | Detail |
|------|--------|
| Sequential only | Never work on two tasks in parallel |
| Test-first always | No production code before a failing test exists |
| Spec-first when present | A `spec_file` must be read and analysed before Step 3 |
| No bypasses | Never use `--no-verify`, never skip security checks |
| Dependency order | Blocked tasks wait; announce which tasks are waiting and why |
| Phase order respected | Outer order follows `implementation_phases`; only deviate when dependencies force it |
| Debugging | If a test fails unexpectedly → invoke `superpowers:systematic-debugging` before changing implementation |
| Unclear criteria | If an acceptance criterion or spec section is technically impossible → stop, document, ask for clarification |
| Verification | Use `superpowers:verification-before-completion` before declaring a task done |
| Status integrity | Only flip a status to `"done"` after the commit succeeded and tests are green |
