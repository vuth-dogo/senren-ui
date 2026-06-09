# Plan 018 - Performance and System Benchmarking

## Purpose

Define Senren UI's CI-safe performance and browser-system-test strategy.

## Scope

- Static performance budgets for component and Stimulus template payloads.
- Headless browser system tests against a tracked dummy Rails app.
- Gross browser performance assertions that are stable enough for CI.

## Decisions

1. The default benchmark tier is CI-safe gates, not competitive framework
   benchmarking.
2. `bin/performance` enforces payload and client-runtime boundaries from
   `config/performance_budgets.yml`.
3. `bin/system` runs Rails system tests against `test/dummy`.
4. `.local/preview` remains a manual preview app and is not required by
   CI.
5. Lighthouse CI is deferred until the docs/preview site has stable URLs.
6. Competitive framework benchmarking is deferred unless Senren needs a
   public comparison report.

## Expected behavior

- Static pages load no Senren controller modules.
- Interactive pages lazy-load only controllers present in the DOM.
- Kitchen-sink pages render every registered component without missing
  template errors.
- Browser tests assert coarse DOM/resource/interaction budgets only.

## Test strategy

- `test/performance_check_test.rb` covers the static budget checker.
- `test/system/*_test.rb` covers static, interactive, and kitchen-sink
  preview routes.
- `bin/ci` runs unit tests, system tests, RuboCop, JavaScript checks,
  and performance checks.

## Acceptance criteria

- [x] `bin/system` passes locally.
- [x] `bin/performance` reads `config/performance_budgets.yml`.
- [x] Static preview proves zero Senren controllers are eagerly loaded.
- [x] Interactive preview proves representative controller behavior.
- [x] Kitchen-sink preview renders every registered component.
- [x] `bin/ci` passes.
