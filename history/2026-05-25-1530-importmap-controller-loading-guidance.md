# 2026-05-25 15:30 - Importmap controller loading guidance

## Goal

Reduce unnecessary initial JavaScript loading in the external
`senren-ui-page` documentation app and clarify how host Rails apps should load
copied Senren Stimulus controllers.

## Changes

- Verified that `config.ru` only boots the Rails application and does not
  control JavaScript mapping, source maps, or minification.
- Changed `senren-ui-page/config/importmap.rb` to preload only the Stimulus
  bootstrap controller modules and defer `site/*` and `senren/*` controllers
  until requested by the existing DOM-priority controller loader.
- Removed the unused `@hotwired/stimulus-loading` page pin because that app
  already uses its own lazy loader.
- Documented `lazyLoadControllersFrom` plus Importmap `preload: false`
  configuration in this gem's README and Stimulus conventions plan for
  consumer applications with many interactive components.

## Verification

- Before the page config change, a production import-map inspection reported
  `preloaded=35` and `controllers=31`.
- After the change, the same inspection reported `preloaded=5` and
  `controllers=2`.
- A production assertion confirmed dynamic mappings still exist for
  representative `site/*` and `senren/*` controllers while feature
  controller preloads remain zero.
- `bin/ci` in `senren-rails-repo` passed: 37 Ruby test runs / 1,617
  assertions, 95 RuboCop-inspected files, and 25 JavaScript controller
  syntax/lint checks.

## Decision

Senren remains a source-copy component library rather than introducing a
bundled runtime. Host applications control bundling, minification, and source
map policy; the library documents the low-cost Importmap configuration that
prevents unused component controllers from loading eagerly.
