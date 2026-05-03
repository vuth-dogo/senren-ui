# Plan 015 — Agent sync review fixes

## Purpose

Address three review findings from the Plan 014 changeset before commit.
Scope is intentionally minimal — no new features, no architectural changes.

## Findings

1. **Inconsistent `registry:` kwarg in deprecated llms task.**
   `senren:llms:generate` in `lib/tasks/senren.rake` creates
   `AgentRulesWriter.new(paths: paths)` without passing `registry:`,
   unlike every other call site. The default works but triggers a
   redundant `Registry.load!`.

2. **Stale checklist text in `plans/011_release_checklist.md`.**
   Two checked items still reference `senren:llms:generate` and
   `public/llms*.txt` which no longer exist in the new flow.

3. **`assert_not` vs `refute` inconsistency in new tests.**
   `agent_rules_writer_test.rb` uses `assert_not` (ActiveSupport)
   while `llms_writer_test.rb` uses `refute` (Minitest native).
   The gem test suite does not load ActiveSupport — standardize on
   Minitest-native `refute`.

## Decisions

1. Pass `registry:` explicitly in the deprecated task.
2. Reword the two checklist items to match the agent sync system.
3. Standardize on `refute` (Minitest-native) in both test files.

## Files modified

- `lib/tasks/senren.rake`
- `plans/011_release_checklist.md`
- `test/agent_rules_writer_test.rb`

## Acceptance criteria

- [x] All three findings resolved.
- [x] `bundle exec rake test` passes.
- [x] `bundle exec rubocop` passes (on changed files).
- [x] History file recorded.
