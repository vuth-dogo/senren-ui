# Plan 010 — Testing Strategy

## Purpose

Define the test layers, frameworks, and required coverage for
Senren v0.1 across both the gem and `apps/todolist`.

## Scope

- Gem unit tests (`test/`).
- Generator tests (`test/generators/`).
- Component render tests (`test/components/`).
- System tests (`test/system/`) using `test/dummy`.
- Integration tests inside `apps/todolist`.

## Decisions

1. Test framework: **Minitest**. Rails-native, zero added deps.
   RSpec is allowed only if the user requests it later; default is
   Minitest.
2. Headless browser for system tests: **Capybara + Selenium with
   headless Chrome**, configured via Rails system test default.
3. Coverage targets:
   - Generators: 100% command paths.
   - Registry: 100% schema validation.
   - Components: render + each variant + each slot.
   - Stimulus controllers (Phase 3+): one happy-path system test
     each.
4. The `apps/todolist` test suite is the integration layer. It runs
   only after gem-level tests pass in CI.
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
senren-rails/test/components/base_component_test.rb
senren-rails/test/components/<name>_component_test.rb   # per component
senren-rails/test/system/<name>_test.rb                  # per interactive component
apps/todolist/test/integration/senren_install_test.rb
apps/todolist/test/integration/todo_crud_test.rb
apps/todolist/test/system/todo_index_test.rb
```

## Files to modify

- `Rakefile` to wire `rake test` and `rake test:system`.
- CI config (out of scope for v0.1, but plan accommodates it).

## Expected behavior

- `bundle exec rake test` runs unit + generator + component tests.
- `bundle exec rake test:system` runs system tests against
  `test/dummy`.
- `apps/todolist` tests run with `bin/rails test` and
  `bin/rails test:system` from `apps/todolist`.
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
- [ ] Phase 1–3 component tests pass.
- [ ] Generator tests cover happy + error paths.
- [ ] Registry schema test loads every component without error.
- [ ] Todolist integration tests pass.
