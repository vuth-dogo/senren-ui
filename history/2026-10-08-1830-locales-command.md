# 2026-10-08 18:30 - `senren:locales vi` as a Rails command

## Goal

Upgrading a host app (CS Copilot) to 0.4.0 found that `bin/rails senren:locales vi`, the spelling every doc and the
install generator use, fails with `Unrecognized command "vi"`.

## Cause

`senren:locales` existed only as a rake task. `bin/rails` hands an unknown command and everything after it to rake,
which reads `vi` as a second task. `senren:add` never had this problem because it is also a Rails command
(`lib/commands/senren/add/add_command.rb`), which receives the words after it as arguments. The i18n work added the
rake task and the docs, but no command, and nothing ran the documented line end to end.

## Changes

- `lib/commands/senren/locales/locales_command.rb`: `perform(*names)` with `--force`, splitting comma-separated names,
  turning the installer's ArgumentError into a command error. Same shape as `AddCommand`. The rake task stays for
  `rake 'senren:locales[vi]'`.
- `test/commands/locales_command_test.rb`.

## Commands run

- A fresh `rails new --minimal` app with the gem by path: `bin/rails senren:locales vi` copies, a re-run skips,
  `--force` replaces, `fr` is refused with the way to add it.
- `bin/ci`

## Audit: every documented command, in a real host app

A fresh `rails new` app (Rails 8.1.4, importmap, Stimulus) with the gem by path, then every `bin/rails senren:*` line
in the README, `docs/` and the generator output. All of them work now, including the legacy bracket forms
(`'senren:add[form,input]'`, `'senren:locales[en]'`, which still reach the rake tasks). Two more defects turned up:

- **`senren:doctor` failed a healthy app.** `✗ ViewComponent gem available`, exit 1. The check was
  `defined?(::ViewComponent)`, and the host's Gemfile lists senren-ui, not view_component, so `Bundler.require` never
  loads it; BaseComponent's `require 'view_component'` runs only when a component is autoloaded. Present since the
  first release. It now falls back to `gem_loadable?('view_component')`, like the Turbo check beside it. The test
  runs the doctor in a clean process, since the test process has ViewComponent loaded.
- **Both commands printed a Thor backtrace for a bad name.** `raise Rails::Command::Base::Error` is not rescued by
  Rails, so the message came out wrapped in ~20 lines of trace. They now `abort e.message`, which is what the rake
  tasks always did: the message on stderr, exit 1.
- `installed_components.yml.tt` named `bin/rails senren:install`; it is `bin/rails generate senren:install`.

## Not changed

- `.senren/conventions.md` is written at install time only, so an upgraded app's copy lacks the `senren_t`
  convention. That is by design: the file is marked "safe to edit" and belongs to the app. The rule reaches agents
  anyway through `.senren/agent-rules.md`, which `bin/rails senren:agents:sync` regenerates and which carries it.
- The `senren_t` append reopens `Senren::BaseComponent` at the end of the host's file. It follows the URL_HELPERS
  precedent and works; rewriting a host's class body in place is riskier than an append.
