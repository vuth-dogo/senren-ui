# Plan 001 — Architecture

## Purpose

Describe the runtime and code-level architecture of `senren-ui`: how
the gem is structured, how it loads into a host Rails app, and how
installed components are organized after `senren:add`.

## Scope

- Gem layout under `lib/`.
- Rails engine boundaries.
- Host app layout after install.
- The contract between the gem (provider) and the host app (owner).

## Decisions

1. `senren-ui` is a **Rails Engine** mounted as a library, not as a
   routable engine. It contributes generators, rake tasks, and view
   helpers. It does **not** mount routes by default.
2. The gem exposes three primary subsystems:
   - **Generators**: `Senren::Install`, `Senren::Component`.
   - **Rake tasks**: `senren:add`, `senren:skill:sync`,
     `senren:llms:generate`, `senren:doctor`.
   - **Library classes**: `Senren::Rails::Registry`,
     `Senren::Rails::Installer`, `Senren::Rails::ComponentCopier`,
     `Senren::Rails::SkillWriter`, `Senren::Rails::LlmsWriter`,
     `Senren::Rails::Doctor`.
3. Component source files live under `templates/components/<name>/` in
   the gem and are **copied verbatim** to the host app under
   `app/components/senren/`. The host app owns them after copy.
4. Stimulus controllers live under `templates/controllers/` in the gem
   and are copied to `app/javascript/controllers/senren/` in the host.
5. The registry is a single YAML file: `registry/components.yml`. Two
   supporting files (`groups.yml`, `recipes.yml`) provide grouping and
   curated multi-component installs.
6. The host app's `.senren/installed_components.yml` is the source of
   truth for what is installed; the gem's registry is the source of
   truth for what is installable.
7. Component code copied into the host has **no runtime dependency on
   the gem**. It uses only `ViewComponent`, `Turbo`, `Stimulus`, and
   Tailwind. The gem is a build-time/install-time dependency only.

## Files to create

```
senren-rails/
  senren-ui.gemspec
  lib/senren/rails.rb
  lib/senren/rails/engine.rb
  lib/senren/rails/version.rb
  lib/senren/rails/registry.rb
  lib/senren/rails/installer.rb
  lib/senren/rails/component_copier.rb
  lib/senren/rails/skill_writer.rb
  lib/senren/rails/llms_writer.rb
  lib/senren/rails/doctor.rb
  lib/generators/senren/install/install_generator.rb
  lib/generators/senren/component/component_generator.rb
  lib/tasks/senren.rake
```

## Files to modify

- Host app `Gemfile` (the consumer adds `gem "senren-ui", require: "senren/rails"`).
- Host app `config/application.rb` (engine auto-loads via Rails).

## Expected behavior

- `require "senren/rails"` loads the engine, version, and library
  classes; it does not touch the host filesystem.
- Generators write files only when invoked.
- Rake tasks read the gem-side registry and write into the host app.
- The host app can boot without the gem after install, because all
  component code lives in `app/components/senren/`.

## Test strategy

- Engine load test in `test/dummy` confirming no side effects on boot.
- Unit tests for `Registry`, `ComponentCopier`, `SkillWriter`,
  `LlmsWriter`, and `Doctor` using a temp directory as fake host app.
- Integration test: run `senren:install` then `senren:add button` in
  `test/dummy` and assert files appear at expected paths.

## Acceptance criteria

- [ ] Gem loads with no host-app side effects.
- [ ] All directories from section 11 of `master_prompt.md` exist.
- [ ] Registry is parseable YAML and validated by a registry test.
- [ ] Removing the gem after install does not break component rendering
      (verified by booting `apps/todolist` with the gem present at
      install time but with components already copied).
