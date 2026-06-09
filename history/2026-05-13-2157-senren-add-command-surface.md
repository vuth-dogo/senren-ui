# 2026-05-13 21:57 - `senren:add` command surface alignment

## Goal

Make `senren:add` work with the natural CLI syntax users expect:
`bin/rails senren:add button input`, while preserving the older bracketed
task form for backward compatibility.

## Changes

- Added `Senren::Command::AddCommand` under `lib/commands/senren/add/`
  so Rails resolves `senren:add` as a first-class command.
- Added `Senren::Rails::ComponentInstaller` to centralize component copy +
  skill sync + agent rules sync behavior.
- Rewired the legacy `lib/tasks/senren.rake` task to reuse the shared
  installer and keep the bracket syntax working.
- Updated installer output, `.senren/conventions` template, README, and
  empty skill guidance to prefer the natural command form.
- Added tests for shared installer behavior plus command parsing/lookup.

## Commands run

```bash
ruby -c lib/senren/rails/component_installer.rb
ruby -c lib/commands/senren/add/add_command.rb
ruby -c lib/tasks/senren.rake
bundle exec ruby -Itest test/component_installer_test.rb
bundle exec ruby -Itest test/commands/add_command_test.rb
bundle exec ruby -Ilib -e 'require "rails/command"; command = ::Rails::Command.find_by_namespace("senren", "add"); abort("missing") unless command; puts command.name'
bundle exec rubocop lib/commands/senren/add/add_command.rb lib/generators/senren/install/install_generator.rb lib/senren/rails.rb lib/senren/rails/component_installer.rb lib/senren/rails/installer.rb lib/senren/rails/skill_writer.rb lib/tasks/senren.rake test/commands/add_command_test.rb test/component_installer_test.rb
bundle exec rake test
```

## Results

- `senren:add` now resolves as `Senren::Command::AddCommand`.
- Natural syntax works at the command layer:
  `bin/rails senren:add button input`
- Alternate entry point is documented and supported:
  `bundle exec rails senren:add button input`
- Legacy bracket syntax remains documented as backward-compatible:
  `bin/rails 'senren:add[button,input]'`
- Ruby test suite passed: `31 runs, 1139 assertions, 0 failures, 0 errors`.
- Targeted RuboCop passed on all changed Ruby files.

## Decisions

- The new command uses `require_application!` instead of booting the full
  environment because component installation only needs app paths plus file
  writes.
- The old task path remains in place so existing docs/scripts do not break
  immediately.

## Next steps

- Revisit the maintainer feedback sweep and validate which remaining items
  are now truly fixed versus still open.
