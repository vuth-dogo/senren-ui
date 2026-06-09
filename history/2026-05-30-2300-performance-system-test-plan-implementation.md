# 2026-05-30 23:00 - Performance System Test Plan Implementation

## Goal

Implement the CI-safe performance and system-test plan for Senren UI.

## Changes

- Added `config/performance_budgets.yml` and made
  `scripts/performance_check.rb` read payload budgets from it.
- Added `bin/system`, wired `bin/ci` and GitHub Actions to run system
  tests, and documented the new local commands.
- Added a tracked DB-less dummy Rails app under `test/dummy` for static,
  interactive, and kitchen-sink component previews.
- Added Selenium/Capybara system tests that assert lazy controller loading,
  representative interactions, external-resource boundaries, and coarse DOM
  and interaction budgets.
- Added exhaustive kitchen-sink preview coverage for every registered
  component.

## Validation

- PASS `bin/test`
- PASS `bin/performance`
- PASS `bundle exec rubocop --cache false`
- PASS `bun run controllers:check`
- PASS `git diff --check`
- PASS `bin/system` outside the sandbox: `4 runs, 95 assertions`
- PASS `bin/ci`
- PASS Rack smoke check for `/components/static`, `/components/interactive`,
  `/components/kitchen_sink`, `/assets/application.js`,
  `/assets/stimulus.js`, and `/assets/controllers/senren/dialog_controller.js`.
- NOTE `bin/system` needs unsandboxed execution in this environment because
  ChromeDriver opens a local `127.0.0.1` control socket.
