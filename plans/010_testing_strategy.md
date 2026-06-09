# Plan 010 — Testing Strategy

## Purpose

Define the test layers, frameworks, and required coverage for
Senren v0.1 across the gem and the local `.local/preview` preview host.

## Scope

- Gem unit tests (`test/`).
- Generator tests (`test/generators/`).
- Component render tests (`test/components/`).
- System tests (`test/system/`) using `test/dummy`.
- Local preview seed tests for `.local/preview`.

## Decisions

1. Test framework: **Minitest**. Rails-native, zero added deps.
   RSpec is allowed only if the user requests it later; default is
   Minitest.
2. Headless browser for system tests: **Capybara + Selenium with
   headless Chrome**, configured via Rails system test default.
3. Coverage targets:
   - Generators: 100% command paths.
   - Registry: 100% schema validation.
   - Components: registry contract coverage plus focused render
     regression tests for high-risk components.
   - Security: static contract tests for component URLs, ERB escaping,
     unsafe SQL APIs, and Stimulus DOM sinks.
   - Performance: local payload budgets for generated component
     templates and Stimulus controller templates.
   - Stimulus controllers (Phase 3+): one happy-path system test
     each.
4. `test/seed_preview_test.rb` covers the lightweight local preview
   integration layer without requiring a checked-in Rails app.
5. Tests must be runnable from the gem root with one command:
   `bundle exec rake test`. System tests via
   `bundle exec rake test:system`.

## Files to create

```
senren-rails/test/test_helper.rb
senren-rails/test/dummy/...                      # minimal Rails app
senren-rails/test/generators/install_generator_test.rb
senren-rails/test/generators/component_generator_test.rb
senren-rails/test/registry/registry_test.rb
senren-rails/test/registry/schema_test.rb
senren-rails/test/components/registry_component_contract_test.rb
senren-rails/test/components/<name>_component_test.rb   # focused regressions
senren-rails/test/security/*_test.rb                    # static security contracts
senren-rails/test/system/<name>_test.rb                  # per interactive component
senren-rails/test/seed_preview_test.rb
```

## Files to modify

- `Rakefile` to wire `rake test` and `rake test:system`.
- CI config (out of scope for v0.1, but plan accommodates it).

## Expected behavior

- `bundle exec rake test` runs unit + generator + component tests.
- `bundle exec rake test:system` runs system tests against
  `test/dummy`.
- `test/seed_preview_test.rb` verifies the generated local preview
  route, Tailwind browser runtime, and `senren.css` import.
- `test/security/*_test.rb` fails fast on unsafe URL protocols,
  server-side escaping bypasses, direct SQL escape hatches, and unsafe
  Stimulus DOM sinks.
- `bin/performance` fails fast when controller/template payloads exceed
  local budgets or client controllers introduce runtime-heavy behavior.
- A failing test prints the offending file path and line.

## Test strategy

(Meta: how we test our tests.)

- Each test file runs in isolation under `bundle exec ruby -Itest
  <file>`.
- No test depends on global state from another test.
- System tests clean up DOM and database between runs.

## Acceptance criteria

- [ ] All four layers exist.
- [ ] One-command test run for each layer.
- [x] Registry-backed component contract test covers every registered
  component class.
- [ ] Focused render regressions exist for high-risk components.
- [ ] Generator tests cover happy + error paths.
- [ ] Registry schema test loads every component without error.
- [x] Static security contract tests cover URL, ERB, SQL, and Stimulus
      guardrails.
- [x] Local performance budgets are runnable with `bin/performance`.
- [x] Local `.local/preview` seed integration test passes.
