# AGENTS.md

## Product overview

MIKIWA is a Rails 8.1 kindergarden management platform. It uses SQLLite, Solid Queue for background jobs, and importmap-rails (no Node.js/npm). It's UI is based on Tailwindcss.

## Tech Stack

- **Language:** Ruby 4.0.3
- **Framework:** Rails 8.1
- **Database:** SQLite (>= 2.1) via Active Record
- **Web server:** Puma, fronted in production by Thruster (HTTP caching/compression, X-Sendfile)
- **Background jobs / cache / cable:** Solid Queue, Solid Cache, Solid Cable (database-backed)
- **Frontend:** Hotwire (Turbo + Stimulus), importmap-rails (no Node.js/npm/bundler), Propshaft asset pipeline
- **Templating:** Haml (`haml-rails`)
- **Styling:** Tailwind CSS (`tailwindcss-rails`); component styles live in CSS files, not inline view classes
- **Testing:** Rails minitest, Capybara + Selenium for system tests
- **Quality / security:** RuboCop (rails-omakase), Brakeman, bundler-audit
- **Deployment:** Docker + Kamal

## Project Navigation

Standard Rails layout. Key entry points:

- `app/` — application code
  - `controllers/`, `models/`, `views/` (Haml), `helpers/`, `mailers/`, `jobs/`
  - `javascript/` — Stimulus controllers and `application.js` import-map entry
  - `assets/stylesheets/` and `assets/tailwind/` — Tailwind sources & component CSS
  - `assets/builds/` — compiled Tailwind output (do not edit)
- `config/` — Rails configuration
  - `routes.rb`, `application.rb`, `database.yml`, `importmap.rb`
  - `queue.yml`, `cache.yml`, `cable.yml`, `recurring.yml` — Solid Queue/Cache/Cable
  - `deploy.yml` (Kamal), `environments/`, `initializers/`, `locales/`
- `db/` — `seeds.rb` plus Solid `*_schema.rb` files (main `schema.rb` generated after first migration)
- `test/` — minitest suites grouped by layer (`controllers/`, `models/`, `integration/`, …) plus `test_helper.rb`
- `lib/tasks/` — custom Rake tasks
- `bin/` — project scripts: `dev` (Procfile.dev runner), `rails`, `rake`, `setup`, `ci`, `jobs` (Solid Queue worker), `kamal`, `brakeman`, `rubocop`, `bundler-audit`, `importmap`, `thrust`
- `Procfile.dev` — local dev processes (`bin/rails server` + `tailwindcss:watch`); start via `bin/dev`
- `.kamal/`, `Dockerfile` — deployment artifacts
- `.github/` — CI workflows
- `script/`, `storage/`, `public/`, `vendor/`, `tmp/`, `log/` — standard Rails directories
- `docs` - all product features, architechture, designs etc.

## Project guardrails

1. Prefer re-using existing UI components from Tailwindcss and additions that are specific for this app, keep styles in CSS files and avoid direct style annotations (e.g. 'semibold', 'text-sm') in the view's code
2. Follow test decisions:
   - Use minitest!
   - Prioritize system tests for critical user flows (golden paths).
   - Add focused tests for custom business logic (services/queries/forms), especially money, permissions, data integrity, and security behavior.
   - Avoid low-value tests that only re-test Rails defaults (basic validations/associations/CRUD wiring) or purely cosmetic UI details.
   - Keep the suite fast and pragmatic; do not add low-risk edge-case tests unless they protect meaningful business risk.
3. Do not assume that smooth migration is absolutely required, ask for clarification in such situations
4. This project builds upon the ideas, philosophy and functionality of the Ruby on Rails framework, stick to them and its best practices. 
5. Prefer a "clear contract" where a component takes responsibility and others can rely on that (e.g. no need for read-time fallback handling if there's a component that validates input at write-time)
6. For **ALL** frontend designs use the `mikiwa-design` skill!
7. Use Stimulus controllers for interactive behavior
8. Business logic goes in dedicated service objects
9. Background jobs use Solid Queue (Rails 8's default job backend) and should be small and idempotent
10. Use conventional commit messages with a brief title and a detailed body. The body can contain asciiart for architectual patterns or introduced design patterns. The body should describe the main changes in a summary easy to read and comprehend.
11. Die Sprache in der Entwicklung für alle Code-Artefakte (User), Tabellen (users), Assets (users_controller.js), etc. ist ENGLISCH.

## STRICT Development/Architecting/Coding Guidelines

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```
