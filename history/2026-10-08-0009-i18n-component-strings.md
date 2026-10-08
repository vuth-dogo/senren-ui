# 2026-10-08 00:09 - Every Component String Is Translatable

Plan: `plans/027_i18n_component_strings.md`.

## Goal

A host app whose UI is not English had no way to translate a Senren component
short of forking its template. Every label, `aria-label`, `sr-only` text,
default `label:`, month name, and four sentences a Stimulus controller wrote
into the page were hard-coded English. The change: route all of them through one
helper with the English as its default, ship the strings as locale files the host
can copy and edit, and keep an app with no locale file rendering exactly what it
did before.

## Changes

**The helper.** `Senren::BaseComponent#senren_t(key, default:, **options)` is
`I18n.t("senren.#{key}", default:, **options)`. Public, so the unit tests that
render a template through a bare `ActionView::Base` (which delegate every public
component method) can reach it. `I18n.t` rather than ViewComponent's `t`: `t`
needs a view context, resolves a leading-dot key against the sidecar scope, and
marks `_html` keys safe, none of which this namespace wants.

**The strings.** 111 keys across 27 components (accordion, alert_dialog,
api_key_field, app_shell, breadcrumb, bulk_action_bar, calendar, carousel, cart,
clipboard, collapsible, combobox, command, data_table, date_picker, dialog,
filter_bar, invite_member_dialog, pagination, product_card, rich_text_editor_lite,
search_input, sheet, sidebar, tabs, theme_toggle, top_nav). A constructor default
`label: 'Tabs'` became `label: senren_t('tabs.label', default: 'Tabs')`: Ruby
evaluates the default when the argument is left out, with the component as
`self`, so an explicit `label: nil` keeps meaning "none". `senren.shared.*` holds
`open` and `close`, the only words two or more components share.

**The controllers.** Five of them wrote English: `clipboard` ("Copied", "Copied
to clipboard"), `api_key_field` ("Copy complete"), `carousel` ("Slide 2 of 3"),
`theme_toggle` ("Light theme", "Dark theme"), `rich_text_editor_lite` (the
`window.prompt`). Each now reads a Stimulus value the component renders. The
carousel's value is the raw template, with `%{current}` and `%{total}` left in:
`I18n.t` interpolates only when values are passed, so
`senren_t('carousel.status', default: 'Slide %{current} of %{total}')` returns the
template untouched.

**The files.** `templates/locales/senren.en.yml` (generated) and
`senren.vi.yml` (written by hand), copied to the host's `config/locales/` by
`lib/senren/rails/locale_installer.rb`, which the install generator
(`--locales en vi`) and a new rake task (`bin/rails senren:locales vi`) both
call. An existing file is skipped unless `--force`.

**Existing installs.** `ComponentCopier` appends `senren_t` to a host's old
`BaseComponent`, the same way it already appends the URL helpers.

**Tooling and docs.** `scripts/i18n_catalog.rb` reads the `senren_t` calls out of
`templates/`; `bin/i18n-sync` writes (or `--check`s) the English file from them.
`docs/i18n.md`, a README section, a rule in `.senren/conventions.md` and the
agent rules, a CONTRIBUTING checklist item, and a CHANGELOG entry under
Unreleased.

## Why the English is in the code and the locale file is generated

The first instinct is a locale file as the source and `t('pagination.next')` in
the template. It fails the main requirement: installing Senren would need a file
in the host, and a host without one would render "translation missing". Keeping
the English as `default:` means nothing is required, a missing key can never
raise (not even under `raise_on_missing_translations`, which fires only for a key
with no default, verified), and `senren.en.yml` becomes a *copy* that can be
checked against the code instead of a second source of truth. `bin/i18n-sync`
writes it and a test compares it.

## What was proved, and how

**Byte-for-byte.** The original commit (`git archive 4aab71e`) and this branch
were each booted through the dummy app and every registered component rendered
with its required arguments plus 42 extra cases that reach conditional branches
(every month, an empty cart, a sold-out product, a tab with no label...), 106
renders.

```
106 renders, 295115 bytes   (4aab71e)
106 renders, 295883 bytes   (this branch)
```

After deleting the six new Stimulus value attributes
(`carousel-status-template`, `theme-toggle-light-label`, `theme-toggle-dark-label`,
`clipboard-copied-status`, `api-key-field-copied-status`,
`rich-text-editor-lite-link-prompt`) from the new output, `cmp` reports the two
documents identical. The four dummy pages (`static`, `interactive`,
`kitchen_sink`, `red_team`) were compared the same way: the only differences
were those six attributes, and the kitchen sink is identical once they are
removed. The existing integration suite that renders every component passed
without a single edit.

**The guards fail when they should.** Four mutations, each checked against the
catalogue test and then reverted: a bare `"Next"` in the pagination ERB, a bare
`label: 'Tabs'`, a bare `aria-label="Close"`, and a `default:` built with
interpolation. All four were reported (7 failures between them). In the browser
test, renaming a Stimulus value in the carousel controller made both the English
and the Vietnamese runs fail.

## Commands run, and what they returned

```
bundle install                       Bundle complete! 11 Gemfile dependencies, 94 gems now installed.
bun install                          36 packages installed  (@biomejs/biome@2.5.6, @herb-tools/linter@0.10.3)
```

Before any change (main @ 4aab71e): `bin/test` 206 runs, 2337 assertions;
`rake test:integration` 63 runs, 251 assertions; `bin/system` 29 runs, 346
assertions; RuboCop 162 files; every other gate green.

After, `bin/ci` on the committed tree:

```
tests                247 runs, 2466 assertions, 0 failures, 0 errors, 0 skips   (+41 runs)
integration tests     77 runs,  310 assertions, 0 failures, 0 errors, 0 skips   (+14)
system tests          31 runs,  364 assertions, 0 failures, 0 errors, 0 skips   (+2)
RuboCop              170 files inspected, no offenses detected
ERB lint             No errors were found in ERB files (68 files, 13 linters)
HTML lint            69 files clean, 0 offenses
JavaScript checks    Syntax check passed: 26 file(s). Checked 26 files, no fixes applied.
performance          PASS x5 (controllers 56017B/56500B, gzip 12896B/14000B;
                     components 146910B/150000B, largest 6839B/8000B)
dependency audit     FAIL  (see below; unrelated to this change)
```

`bin/i18n-sync --check`: `templates/locales/senren.en.yml is up to date (111 keys)`.

**The audit failure is not from this branch.** `bundle-audit` reports
`rubyzip 3.3.1`, CVE-2026-85396 / GHSA-47m2-wp7j-p9vc (path traversal, fixed in
>= 3.4.0). rubyzip comes in through selenium-webdriver; `Gemfile.lock` is
untouched here, so `main` fails the same gate today. In a throwaway copy of the
Gemfile and lock, `bundle update rubyzip --conservative` moves it to 3.7.0 and
`bundle-audit check` then prints `No vulnerabilities found`. Not applied: it is
outside this change.

**`bin/matrix` fails on Rails 7.1, 7.2 and 8.0, and fails the same way on main.**
Unit tests pass on all four (247 runs each). `test:integration` raises
`ArgumentError: unknown keyword: quirks_mode` on 7.1, 7.2 and 8.0. The matrix
lockfiles resolve `json 3.0.2`, which removed the `quirks_mode:` argument that
ActiveSupport's JSON encoder passes when ActionView serialises a non-string
`data-` value such as `open: false`. Running the original commit (4aab71e)
through the same gemfiles gives `63 runs, 137 assertions, 4 failures, 26 errors`
on both 7.1 and 8.0, with the same message. With `json` pinned below 3 in
throwaway gemfiles (removed afterwards), this branch passes on all three. These
runs were taken before the packaging test gained its five entries, which is why
they show 2458 assertions where the final `bin/ci` shows 2466; the number of
runs is the same:

```
Rails 7.1.6   247 runs, 2458 assertions, 0 failures   /   77 runs, 310 assertions, 0 failures
Rails 7.2.3   247 runs, 2458 assertions, 0 failures   /   77 runs, 310 assertions, 0 failures
Rails 8.0.5.1 247 runs, 2458 assertions, 0 failures   /   77 runs, 310 assertions, 0 failures
Rails 8.1.4   247 runs, 2458 assertions, 0 failures   /   77 runs, 310 assertions, 0 failures  (bin/matrix, as is)
```

The matrix lockfiles are git-ignored and resolved fresh on every run, so
GitHub's matrix job most likely meets the same break. A pin such as
`gem 'json', '< 3'` in `gemfiles/common.rb` is the likely fix; it is a separate
change.

## Decisions worth keeping

- **`en` is installed by default, other locales are asked for.** A shipped
  translation adds its locale to `I18n.available_locales`, and a language
  switcher built from that list would then offer it. For the same reason the
  files are under `templates/locales/`, not `config/locales/`: an engine
  auto-loads `config/locales` from its own root, which would load `:vi` into
  every app that merely bundles the gem.
- **The first design was wrong and was replaced.** Constructor defaults were
  `nil` with a lookup when read. That changes what an explicit `nil` means, and
  in a combobox or a nav `nil` is how a caller removes the text. The
  default-argument form keeps it.
- **The marker test earned its place.** `test_every_key_in_the_catalogue_reaches_the_markup`
  first reported 13 unreachable keys: `bulk_action_bar.items` and twelve months.
  They were reachable; the marker for the sentence around them had dropped the
  variable that carries them. It now keeps each key's `%{}` variables, which is
  also what proves a nested key (a month inside a title) is reached.
- **`Style/FormatStringToken` is `conservative`.** Every translatable string uses
  `%{name}`; the default mode reads each as a bad format string.
- **Two budgets raised, with reasons** in `config/performance_budgets.yml`:
  components 140000 -> 150000 (+9289B actual), controllers 56000 -> 56500
  (+317B actual).
- A value interpolated into a translation is text. A cart item named `<b>Mug</b>`
  reaches `aria-label` as those characters and is never parsed into an element;
  there is a test for it.

## Seen and not fixed

- **`rubyzip` CVE and the `json 3.0.2` matrix break** (above). Both predate this
  change and both block a green `bin/ci` / `bin/ci --matrix`.
- **`test/dummy/app/javascript/vendor/stimulus_lite.js` is not faithful to
  Stimulus in three ways.** It binds `data-action` only on descendants of the
  controller element, so `theme_toggle` (whose action sits on the controller
  element itself) cannot be clicked in the harness; it has no `has<Name>Value`;
  and a missing String value reads `null` where Stimulus gives `""`. The system
  test works around the first by calling the controller, and the controllers
  avoid the second by checking truthiness.
- **The calendar is Sunday-first in every locale.** Vietnamese calendars start on
  Monday. A `first_day_of_week` argument is a feature, not a translation.
- **Words the brief listed that the library does not have:** "Loading" and
  "Select all". Nothing to translate, nothing added. The command palette's "No
  results found." is covered.
- **A table or data table header built from a column key** (`:created_at` ->
  "Created at") is data, not text, and is not translated; pass `label:` on the
  column.
- **Components already in a host keep their English** until they are copied
  again (`senren:add <name> --force`, which replaces local edits). `senren:doctor`
  could report a host that has no `config/locales/senren.en.yml` or whose
  `BaseComponent` lacks `senren_t`; it does neither today.
- **`sidebar` and `top_nav` default their brand to "Senren".** It is translatable
  like the rest, but it is a product name; a host should pass `brand:`.
- `senren-ui-page`, the docs site that lives outside this repository, has no page
  for translation yet.
