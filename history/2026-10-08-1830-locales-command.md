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

## Not changed

- An unknown locale prints the command error with a backtrace, exactly as `senren:add <unknown>` already does.
- From the same upgrade report: the `senren_t` append reopens `Senren::BaseComponent` at the end of the host's file
  (the URL_HELPERS precedent), and `.senren/conventions.md` is written at install time only, so an upgraded app does
  not get the i18n convention. Both are left for a follow-up.
