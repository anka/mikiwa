---
name: write-test
description: Write Minitest unit, controller/integration, or mailer tests for Ruby on Rails. Use when given a feature description or a specific class/method to test. Enforces 10 core testing principles and emits ready-to-run test files that match the Mikiwa project conventions.
argument-hint: "<feature description or class/method to test, with context>"
---

# Write Test

Write Minitest tests for Ruby on Rails. Accepts a description of what to test and produces
ready-to-run test files that strictly follow project conventions and the 10 core principles below.

## Usage

```
/write-test $ARGUMENTS
```

---

## 10 Core Principles

Every test written with this skill MUST satisfy all 10 principles. Treat them as hard constraints,
not guidelines.

| # | Principle | What it means in practice |
|---|-----------|---------------------------|
| 1 | **Test behavior, not implementation** | Assert public outcomes (return values, DB state, HTTP responses, emails sent). Never assert on private methods, internal variables, or how the code achieves its result. |
| 2 | **AAA pattern** | Every test body has exactly three logical blocks: **Arrange** (set up data/state), **Act** (call the code under test), **Assert** (verify outcomes). Separate them with a blank line when more than two lines. |
| 3 | **One responsibility per test** | One test = one behavior. If you need `and` in the test name, split it. |
| 4 | **Determinism** | No `rand`, `Time.now`, `Date.today`, `SecureRandom` (except in fixtures where value is irrelevant). Freeze time with `travel_to` when date/time matters. Always use explicit, fixed values. |
| 5 | **Isolation** | Tests must pass in any order, any subset. No shared mutable state between tests. Use `setup` / `teardown` or `let`-style instance vars to recreate state per test. |
| 6 | **Test pyramid** | Prefer model tests > controller tests > integration tests. Add a system (browser) test only when testing a JavaScript-heavy or multi-step UI flow that cannot be covered at a lower level. |
| 7 | **Edge cases and failure paths** | For every happy-path test, write at least one test for: an invalid input, a missing required value, an unauthorized actor, or a boundary condition. |
| 8 | **Readability and intent clarity** | Test names read like documentation: `"parent cannot update another family's child"`. Use named local variables over inline literals. Prefer `assert_equal expected, actual` over `assert result == expected`. |
| 9 | **Mock only external boundaries** | Stub/mock network calls, external APIs, file uploads (use fixtures or `file_fixture`), and email delivery (already stubbed by Rails). Never mock ActiveRecord, the router, or application services unless testing the caller in isolation is essential. |
| 10 | **Fast and data-explicit** | Inline `Model.create!` in `setup` with all required attributes spelled out. Avoid loading more fixtures than necessary. Use `assert_no_difference` / `assert_difference` over re-querying when possible. |

---

## Workflow

### 1. Understand What to Test

Parse `$ARGUMENTS` for:

- **Target**: class name, method, controller action, or feature description
- **Scope**: model / controller / mailer / integration / system
- **Context clues**: roles involved, edge cases mentioned, related models

If the argument is ambiguous, ask one focused question before proceeding.

### 2. Read the Source

Before writing a single test line:

1. Read the source file for the class under test.
2. Read any related model for validations, associations, scopes, and callbacks.
3. Read `test/test_helper.rb` and `test/test_helpers/session_test_helper.rb` to understand available helpers.
4. Skim existing tests in the same directory to match style.

### 3. Choose the Test Class

| What you are testing | Test superclass | File location |
|----------------------|-----------------|---------------|
| Model methods, validations, callbacks, scopes | `ActiveSupport::TestCase` | `test/models/<name>_test.rb` |
| Controller actions, authorization, HTTP responses | `ActionDispatch::IntegrationTest` | `test/controllers/<name>_test.rb` |
| Mailer templates and delivery | `ActionMailer::TestCase` | `test/mailers/<name>_test.rb` |
| Multi-step UI flows with JS | `ApplicationSystemTestCase` | `test/system/<name>_test.rb` |

### 4. Generate the Tests

Produce a complete, runnable test file. Follow the structure in **Output Format** below.

Cover:
- All public methods or actions mentioned in the argument
- Happy path for each
- At least one invalid/edge-case path per behavior
- Authorization checks (if a controller action) for each relevant role

### 5. Review Checklist

Before emitting the file, verify every test against the 10 principles:

- [ ] Asserts on behavior/outcome, not internal state
- [ ] Has a clear Arrange / Act / Assert structure
- [ ] Tests exactly one thing
- [ ] Uses fixed, explicit data (no `Time.now`, no `rand`)
- [ ] Does not depend on other tests' side effects
- [ ] Lives at the right pyramid level
- [ ] Includes at least one edge/failure test per happy path
- [ ] Test name describes intent in plain language
- [ ] No mocks of Rails internals or application services
- [ ] `setup` block creates all required data inline with `create!`

---

## Project Conventions

### Authentication

Use `sign_in_as(user)` from `SessionTestHelper` (automatically included in
`ActionDispatch::IntegrationTest`):

```ruby
setup do
  @caretaker = User.create!(email: "betreuer@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
end

test "caretaker can access resource" do
  sign_in_as(@caretaker)
  get resource_path
  assert_response :success
end
```

### Roles

Mikiwa has three roles: `"admin"`, `"caretaker"`, `"parent"`. Authorization tests must cover
all roles that are expected to be allowed AND at least one that should be denied.

### User Creation

Always use explicit, unique email addresses. Append a short suffix to avoid collisions:

```ruby
User.create!(email: "admin_test@mikiwa.at", password: "adminpasswort1234567", role: "admin")
```

### Assertions for HTTP

| Scenario | Assertion |
|----------|-----------|
| Successful HTML response | `assert_response :success` |
| Redirect after create/update | `assert_redirected_to some_path` |
| Authorization denied | `assert_response :forbidden` |
| Validation failure | `assert_response :unprocessable_entity` |
| Record count change | `assert_difference "Model.count", +1 do ... end` |
| No change | `assert_no_difference "Model.count" do ... end` |

### Mailer Tests

```ruby
test "delivers invitation to correct address" do
  # Arrange
  user = User.create!(email: "eingeladen@mikiwa.at", password: "sicherespasswort1234", role: "parent")

  # Act
  assert_emails 1 do
    InvitationMailer.with(user: user).invite.deliver_now
  end

  # Assert
  mail = ActionMailer::Base.deliveries.last
  assert_equal ["eingeladen@mikiwa.at"], mail.to
end
```

### Time-Sensitive Tests

Use `travel_to` when the test depends on a specific date or time:

```ruby
test "event is in the past after end_date" do
  travel_to Date.new(2026, 8, 1) do
    event = Event.new(start_date: Date.new(2026, 7, 10), ...)
    assert event.past?
  end
end
```

### UUID Primary Keys

When asserting on IDs, match the UUID format:

```ruby
assert_match(/\A[0-9a-f-]{36}\z/, record.id)
```

---

## Output Format

Emit a complete Ruby test file. Do not wrap in markdown fences — output only the raw `.rb` content.

```ruby
require "test_helper"

class <ClassName>Test < <SuperClass>
  setup do
    # All data required by the tests below, created inline with create!
  end

  # --- Happy path ---

  test "<behavior in plain language>" do
    # Arrange
    # (additional setup specific to this test, if any)

    # Act
    # (single operation under test)

    # Assert
    # (one or two assertions on the observable outcome)
  end

  # --- Edge cases / failure paths ---

  test "<what breaks or is rejected>" do
    # ...
  end

  # --- Authorization (controller tests only) ---

  test "<role> cannot <action>" do
    # ...
  end
end
```

### File placement rules

- Emit the correct file path as a comment on line 1: `# test/models/foo_test.rb`
- Use the naming convention `<subject>_test.rb`
- One test class per file unless testing two tightly coupled behaviors

---

## Tips

- If the argument describes a whole feature (multiple models + controller), write separate test
  files and emit them one after the other, each preceded by its file path comment.
- When a validation constraint appears in the model, there must be a corresponding test that
  verifies the record is invalid without that attribute.
- Avoid `assert_equal true, expr` — use `assert expr` (or `assert_predicate`).
- Avoid `assert_equal false, expr` — use `assert_not expr` (or `refute`).
- `assert_raises(ErrorClass) { ... }` is preferred over rescuing in the test body.
- Never use `binding.pry` or `debugger` in emitted test files.
