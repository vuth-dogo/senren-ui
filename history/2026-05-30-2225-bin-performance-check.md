# 2026-05-30 22:25 — Bin Performance Check

## Goal

Add a local `bin/` command for performance regression checks that fits
the Senren gem/source-copy architecture.

## Changes

- Added `bin/performance`.
- Added `scripts/performance_check.rb` with local payload budgets for:
  - total Stimulus controller template bytes,
  - gzipped Stimulus controller template bytes,
  - largest single controller template,
  - total component Ruby/ERB template bytes,
  - largest single component Ruby/ERB template.
- Added `test/performance_check_test.rb` covering passing budgets,
  oversize controller failure, runtime-heavy controller failure, and
  missing lazy-loading guidance failure.
- Added static performance boundaries that reject Stimulus network calls
  and external UI framework imports.
- Wired `bin/performance` into `bin/ci` and GitHub Actions CI.
- Documented the command in README, CONTRIBUTING, and plans.

## Decisions

- This repo is not a full Rails app, so the first local performance gate
  focuses on generated payload size and client runtime boundaries.
- Database/N+1 profiling remains a host-app concern.
- Render profiling remains a host-app concern via Rails instrumentation,
  Rack Mini Profiler, or production APM.

## Validation

- `bin/performance` passed:
  - Stimulus controller payload: `39603B` total, `8134B` gzipped,
    largest controller `14393B`.
  - Component template payload: `113025B` total, largest template
    `6783B`.
  - Stimulus runtime boundaries passed.
  - Importmap lazy-loading guidance check passed.
- `bundle exec rubocop --cache false scripts/performance_check.rb`
  passed.
- `bin/ci` passed: focused tests, full Ruby suite, RuboCop, JS checks,
  and performance checks.
- Follow-up validation after adding checker tests:
  - `bundle exec ruby -Itest test/performance_check_test.rb` passed
    with 4 runs and 18 assertions.
  - `bin/ci` passed with 56 Ruby test runs, 1,702 assertions, 101
    RuboCop-inspected files, 25 JavaScript controller checks, and the
    performance budget checks.
- `git diff --check` passed.

## Next Steps

- Consider adding optional host-app render timing examples once the
  `.local/preview` app has stable system/browser coverage.
