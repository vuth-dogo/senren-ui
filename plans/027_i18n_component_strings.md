# Plan 027 - Translatable Component Strings

## Purpose

Let a host app whose UI is not English translate everything a Senren component
shows or announces without forking a template.

Today every such word is hard-coded English: the visible labels ("Previous",
"Next", "Close", "Copy", "Today"), the `aria-label` and `sr-only` texts
("Toggle sidebar", "Go to slide 2"), the default `label:` arguments (`Tabs`,
`Pagination`, `Command menu`), the month and weekday names in the calendar, and
four strings a Stimulus controller writes into the page after load ("Copied",
"Slide 1 of 3", "Light theme", a `window.prompt`). The only way to change any of
them is to edit the copied source of every component that carries one, and to
repeat that edit after every `--force` upgrade.

Related upstream: issue #1 and the pagination labels.

## Scope

In scope:

- One translation helper on `BaseComponent`, and every user-facing or
  screen-reader string in every component routed through it.
- The four controller strings, supplied by the server instead of hard-coded in
  JavaScript.
- Shipped locale files: `en` (canonical) and `vi`, copied into the host app.
- The installer wiring, the docs, and the tests that stop the catalogue from
  drifting.

Out of scope:

- Right-to-left layout, pluralisation rules beyond what `I18n` already does,
  date and number formatting. Money, dates and numbers arrive formatted from the
  host, as before.
- New components or new strings. The brief mentions "Loading", "No results" and
  "Select all"; the library has no loading state and no select-all control, so
  there is nothing to translate and nothing is added.
- Translating text the caller supplies (titles, labels, slot content), and text
  derived from caller data: `TableComponent` and `DataTableComponent` build a
  header from a column key (`:created_at` -> "Created at"). Pass `label:` on the
  column to control it.
- Glyph-like labels that are symbols, not words: the dialog `×`, the cart `+`
  and `−`, the required-field `*`, and the rich text toolbar's `P`, `H1`-`H3`,
  `B`, `I`, `1.`.
- Any other locale. `vi` is shipped because it is the second language of the
  first consumer; the file format and the `senren:locales` task are what let
  anyone add a third.

## Decisions

1. **One helper, `senren_t(key, default:, **options)`.** It is
   `I18n.t("senren.#{key}", default: default, **options)` and nothing else.
   `I18n.t` rather than ViewComponent's `t` because `t` needs a view context, so
   it cannot run in the unit tests that render a template without Rails; it
   resolves a leading-dot key relative to the component's own sidecar scope,
   which is the lookup this namespace must not have; and it returns `html_safe`
   for keys ending in `_html`, which this library never wants. A plain `String`
   goes through ERB's normal escaping.
2. **The English stays in the code, as `default:`.** This is what keeps
   installing Senren a zero-configuration step. With no locale file in the host
   app every component renders byte-for-byte what it rendered before; the
   locale file is only needed to *change* a word. It is also why a missing
   translation can never raise, including when the host sets
   `config.i18n.raise_on_missing_translations = true`: `I18n` only reports a
   missing key when no default was given.
3. **Keys are `senren.<component>.<key>`, snake_case, one namespace per
   component.** `senren.shared.*` holds only words that are the same word in
   more than one component. Today that is `open` (the hidden fallback trigger of
   `dialog`, `sheet` and `alert_dialog`) and `close` (the close button of
   `dialog` and `sheet`). A key under `shared` that fewer than two components
   use fails a test, so the namespace cannot become a dumping ground.
4. **A constructor default of `'Tabs'` becomes `nil`, resolved when it is
   read.** `TabsComponent.new(label: nil)` and `TabsComponent.new` both give the
   translated default; `label: 'Menu'` is used verbatim and never looked up;
   `label: ''` renders empty. Resolving at read time rather than in
   `initialize` means the locale in force when the component renders is the one
   that applies. The one behaviour change: an explicit `nil` used to mean "no
   text" in a handful of places and now means "the default". `''` is the way to
   ask for nothing, and the docs say so.
5. **Variables use `%{name}`; the string a JavaScript controller needs is the
   raw template.** `I18n` interpolates only when values are passed, so
   `senren_t('carousel.status', default: 'Slide %{current} of %{total}')` with
   no values returns the template untouched. The server renders it into a
   Stimulus value and the controller substitutes the two placeholders. Values
   interpolated into a translation are plain strings and are escaped by ERB, as
   the ERB they replace was.
6. **The gem ships the locale files from `templates/locales/`, not
   `config/locales/`.** A Rails engine auto-loads `config/locales` from its own
   root. That would put `:vi` into `I18n.available_locales` of every app that
   merely bundles the gem, which is exactly what a language switcher built from
   `I18n.available_locales` would then list. It would also bypass the model this
   library is built on: the host owns the copy. So they sit next to the other
   source that gets copied, and land in the host as `config/locales/senren.en.yml`
   and `config/locales/senren.vi.yml`.
7. **`en` is installed by default; any other shipped locale is asked for by
   name.** `senren:install` copies `senren.en.yml`, so every key and its current
   wording is in the host app to read and edit. `--locales en vi` on the
   generator, or `bin/rails senren:locales vi` later, adds another. An existing
   file is never overwritten without `--force`: it is the host's translation,
   not generated state.
8. **The file is not in the registry.** Registry `files:` are per component and
   validated against a fixed allowlist of three paths. The locale file is one
   shared file whose keys cover every component, so it is wired through the
   installer instead, like `senren.css` and the conventions file.
9. **`senren:add` makes sure the helper exists.** A component copied into a host
   whose `BaseComponent` predates `senren_t` would raise `NoMethodError` on
   first render. The copier already solves the same problem for `safe_url`; it
   now does the same for `senren_t`, by appending the helper to the host's file
   when it is absent. The two copies of the helper are pinned together by a test.
10. **`en.yml` is generated from the code; `vi.yml` is written by a person.**
    `bin/i18n-sync` reads every `senren_t(key, default:)` call out of the
    templates and writes `senren.en.yml`; a test compares the two, so the file
    cannot drift from the strings. Nothing can generate a good Vietnamese
    sentence, so `vi` is hand-written and a test checks it has exactly the same
    keys and the same `%{}` variables as `en`.
11. **A template that shows an English word the catalogue does not know about
    fails a test.** Without that, the next component would reintroduce the
    problem. The check reads every ERB text node and every `aria-label`,
    `title`, `placeholder`, `alt` attribute, and every string default in a
    component's `initialize`, and fails on a bare word that is not in the
    allowlist (identifiers like `name: 'q'` are, by parameter name).
12. **An id derived from a label follows the displayed text.** `Command`, `Cart`,
    `InviteMemberDialog` and `Tabs` derive a DOM id from their title or label.
    In English that is unchanged; in another language the id is derived from the
    translated words, deterministically, as before.
13. **The performance budget for component source is raised, and says why.** The
    templates were 137,621 of 140,000 bytes. Every string now carries a key and a
    call, so the set grows by a few kilobytes. The budget moves with a recorded
    reason, as it did in plan 024, rather than being nudged.

## Files to create

- `plans/027_i18n_component_strings.md` - this file.
- `templates/locales/senren.en.yml` - every key, the canonical English.
- `templates/locales/senren.vi.yml` - the same keys, in Vietnamese.
- `lib/senren/rails/locale_installer.rb` - copies a shipped locale file into the
  host, refusing to write outside the app root and never overwriting without
  `--force`.
- `scripts/i18n_catalog.rb` - reads the `senren_t` calls from `templates/` and
  builds the catalogue; development tooling, not shipped.
- `bin/i18n-sync` - writes (or with `--check`, verifies) `senren.en.yml`.
- `docs/i18n.md` - how it works, how to translate, how to add a language.
- `test/i18n_catalog_test.rb` - the catalogue, `en`, `vi` and the bare-English
  guard (unit, no Rails).
- `test/locale_installer_test.rb` - the copy, the skip, `--force`, containment.
- `test/integration/i18n_rendering_test.rb` - defaults equal `en`, a host
  translation changes the output, every key reaches the markup.
- `history/2026-10-07-HHMM-i18n-component-strings.md`.

## Files to modify

- `lib/generators/senren/install/templates/base_component.rb.tt` - `senren_t`.
- `lib/senren/rails/base_component_patch.rb`, `lib/senren/rails/component_copier.rb`
  - the same helper for hosts that already have a `BaseComponent`.
- `lib/senren/rails/host_paths.rb` - `locales_dir`, `locale_file`.
- `lib/generators/senren/install/install_generator.rb` - `--locales`, and the
  copy.
- `lib/tasks/senren.rake` - `senren:locales`.
- `lib/generators/senren/install/templates/conventions.md.tt` and
  `lib/senren/rails/agent_rules_writer.rb` - the rule, for people and agents.
- 27 components under `templates/components/`: accordion, alert_dialog,
  api_key_field, app_shell, breadcrumb, bulk_action_bar, calendar, carousel,
  cart, clipboard, collapsible, combobox, command, data_table, date_picker,
  dialog, filter_bar, invite_member_dialog, pagination, product_card,
  rich_text_editor_lite, search_input, sheet, sidebar, tabs, theme_toggle,
  top_nav.
- Six controllers under `templates/controllers/`: api_key_field, carousel,
  clipboard, rich_text_editor_lite, theme_toggle, and the values they read.
- `config/performance_budgets.yml`, `README.md`, `CONTRIBUTING.md`,
  `CHANGELOG.md`.
- `test/generators/install_generator_test.rb`, `test/component_copier_test.rb`
  - the new install behaviour.

## Expected behavior

- With no `senren.*` key anywhere, every component renders exactly the HTML it
  rendered before this change.
- With `config/locales/senren.en.yml` installed, the output is still identical.
- With `config/locales/senren.vi.yml` installed and `I18n.locale = :vi`,
  `PaginationComponent` renders "Trước" and "Sau", the calendar renders
  "Tháng 5 năm 2026" and `CN T2 T3 T4 T5 T6 T7`, the carousel announces
  "Slide 1 trên 3", and the theme toggle swaps to "Giao diện sáng" on click.
- A host that defines only `senren.pagination.next` gets that one word
  translated and everything else in English.
- A caller's own `label:`, `placeholder:` or `empty_text:` is used verbatim and
  never looked up.
- A missing key never raises, with or without
  `config.i18n.raise_on_missing_translations`.
- `bin/rails generate senren:install` writes `config/locales/senren.en.yml`;
  `--locales en vi` writes both; `bin/rails senren:locales vi` adds one later;
  an existing file is skipped unless `--force`.
- `bin/rails senren:add pagination` in a host with an old `BaseComponent` makes
  `Senren::BaseComponent#senren_t` exist.

## Test strategy

- **The catalogue is checked against the code.** Every `senren_t` call has a
  literal key and a literal default; one key never has two defaults; each
  component uses only its own namespace or `shared`; `senren.en.yml` equals the
  generated catalogue, key for key and in order; `vi` has the same keys and the
  same `%{}` variables; every YAML key is a string (a bare `no` or `on` key is a
  boolean in YAML 1.1).
- **Defaults are proved equal to `en`.** Every registered component is rendered
  with an empty backend and again with `senren.en.yml` loaded; the HTML is
  identical. This is the byte-for-byte guarantee, and it is checked on the
  rendered markup, not on the strings.
- **A host translation changes the output.** Pagination "Next" becomes "Sau"
  through a single `store_translations`; with the whole `vi` file loaded the
  component output differs from English and nothing raises on a missing
  interpolation.
- **Every key reaches the page.** A marker locale maps each key to `⟦key⟧`; the
  components are rendered with arguments that exercise their conditional
  branches, and every key in the catalogue must appear. A key nothing renders is
  a dead translation.
- **No bare English.** The guard in decision 11, so a future component cannot
  skip the helper unnoticed.
- **The controllers stay honest.** `bun run controllers:check` and
  `bin/performance` stay green, and the markup test asserts each new Stimulus
  value is present and carries the translated string.
- **The migration.** The copier test starts from an old `BaseComponent` and
  asserts `senren_t` exists afterwards; a pin test asserts the patched helper and
  the template helper are the same code.
- Every existing test stays green and unchanged.

## Acceptance criteria

- `bin/ci` passes: tests, integration tests, system tests, RuboCop, ERB lint,
  HTML lint, JavaScript checks, performance, dependency audit.
- The integration suite that renders all registered components passes without a
  single edit.
- `bin/i18n-sync --check` passes.
- A grep for a hard-coded user-facing English string in `templates/` finds only
  what the plan lists as out of scope.
- The README and `docs/i18n.md` say how to translate and how to add a language.
