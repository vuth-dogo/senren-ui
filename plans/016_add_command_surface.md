# Plan 016 — `senren:add` command surface alignment

## Purpose

Make `senren:add` behave the way the docs and installer already imply:
support natural Rails command syntax like `bin/rails senren:add button input`
while keeping the older bracketed Rake task syntax working.

## Scope

- Add a real Rails command for `senren:add`.
- Reuse one shared installation path for the command and the legacy task.
- Update onboarding/docs/examples to prefer the natural command syntax.
- Add tests that validate command lookup, CLI option parsing, and shared
  installation behavior.

## Decisions

1. Add `Senren::Command::AddCommand` under `lib/commands/**` so Rails can
   resolve `senren:add` as a first-class command.
2. Extract component installation orchestration into
   `Senren::Rails::ComponentInstaller` so the command and legacy Rake task
   stay in sync.
3. Keep the old bracket form
   `bin/rails 'senren:add[button,dialog]'` as a backward-compatible path.
4. Avoid booting the full Rails environment for the new command because the
   operation only needs app paths plus file copying/sync.

## Files to create

- `lib/commands/senren/add/add_command.rb`
- `lib/senren/rails/component_installer.rb`
- `test/commands/add_command_test.rb`
- `test/component_installer_test.rb`

## Files to modify

- `README.md`
- `lib/generators/senren/install/install_generator.rb`
- `lib/generators/senren/install/templates/conventions.md.tt`
- `lib/senren/rails.rb`
- `lib/senren/rails/installer.rb`
- `lib/senren/rails/skill_writer.rb`
- `lib/tasks/senren.rake`

## Expected behavior

- `bin/rails senren:add button dialog` works.
- `bundle exec rails senren:add button dialog` works.
- `bin/rails 'senren:add[button,dialog]'` still works.
- `--client`, `--no-client`, and `--force` behave consistently across both
  entry points.

## Test strategy

- Unit test the shared installer in a temp host app directory.
- Unit test command discovery plus option parsing using a stub installer.
- Run targeted gem tests for the new files, then the full Ruby test suite.

## Acceptance criteria

- [x] Natural `senren:add` command syntax is implemented.
- [x] Legacy bracket syntax remains supported.
- [x] Onboarding/docs prefer the natural syntax.
- [x] Tests cover command parsing and installer behavior.
