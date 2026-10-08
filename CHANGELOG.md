# Changelog

All notable changes to `senren-ui` are recorded here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
v0.x is a pre-stable line: minor bumps may break things; patch bumps are
bug fixes only.

## [0.4.1] — 2026-10-08

### Fixed

- `bin/rails senren:locales vi`, as the README, `docs/i18n.md` and the install
  generator write it, failed with `Unrecognized command "vi"`: the task was a
  rake task only, so Rails passed `vi` to rake as a second task name, and the
  one spelling that worked was `bin/rails 'senren:locales[vi]'`. It is now a
  Rails command, like `senren:add`, so `bin/rails senren:locales vi`,
  `senren:locales en vi` and `senren:locales vi --force` work as documented.
- `bin/rails senren:doctor` reported `✗ ViewComponent gem available` and exited
  1 on a healthy app. It checked only whether the `ViewComponent` constant was
  loaded, and a host's Gemfile lists `senren-ui`, not `view_component`, so
  nothing loads it until the first component renders. The check now also asks
  whether the gem is installed, as the Turbo check already did.
- `bin/rails senren:add` and `senren:locales` given a name they do not know (or
  `senren:add` given none) printed a Thor backtrace with the useful line at the
  top of it. They now print the message alone and exit 1, as the rake tasks
  always did.

## [0.4.0] — 2026-10-08

### Added

- **Every word a component shows or announces can be translated from the host
  app, without editing a component.** Visible text, `aria-label` and `sr-only`
  text, the defaults of `label:`, `placeholder:` and `empty_text:`, the
  calendar's month and weekday names, and the sentences a Stimulus controller
  says after load now go through one helper, `senren_t`, with the English as its
  default: `senren_t('pagination.next', default: 'Next')` is
  `I18n.t("senren.pagination.next", default: "Next")`. 111 keys across 27
  components, named `senren.<component>.<key>`, with `senren.shared.*` for the
  two words that are the same word in several components.

  An app with no locale file renders exactly what it did before, and a missing
  translation never raises, including under
  `config.i18n.raise_on_missing_translations`. Text you pass in yourself is used
  as given and never looked up; `label: nil` still means "none", and leaving the
  argument out is what gets the translated default.

  The gem ships `senren.en.yml` and `senren.vi.yml`, and copies either only
  when asked for: `bin/rails generate senren:install --locales vi`, or later
  `bin/rails senren:locales vi`. Not even English is copied by default: a copied
  `senren.en.yml` loads after the app's `en.yml`, overriding any `senren.*` key
  set there, and pins today's wording against later releases. An existing file
  is never overwritten unless that is asked for by name
  (`senren:locales vi --force`, or `senren:install --force-locales`); the
  `--force` that refreshes Senren's own files leaves translations alone. To add
  another language, `bin/rails senren:locales en`, copy the file, change `en:`,
  and translate the values. A translation with a misspelt `%{variable}` falls
  back to the English instead of raising. See [docs/i18n.md](docs/i18n.md).

  `bin/i18n-sync` regenerates `templates/locales/senren.en.yml` from the code,
  and a test fails if it, `senren.vi.yml`, and the components disagree, or if a
  template shows a word that did not go through `senren_t`.

### Changed

- **Five Stimulus controllers no longer carry an English sentence.** `clipboard`
  ("Copied", "Copied to clipboard"), `api_key_field` ("Copy complete"),
  `carousel` ("Slide 2 of 3"), `theme_toggle` ("Light theme", "Dark theme") and
  `rich_text_editor_lite` (the link prompt) read the sentence from a Stimulus
  value the component renders, so they speak the host's language. The markup
  gains six `data-senren--<controller>-…-value` attributes and is otherwise
  byte-for-byte what it was.

  **Migrate:** none for an unmodified install. The controller and its component
  go together: if you copied a component and edited its controller, or the other
  way round, copy both again (`bin/rails senren:add <name> --force`) so the value
  the controller reads is the one the component writes.
- `bin/rails senren:add` appends `senren_t` to an existing
  `app/components/senren/base_component.rb` that lacks it, so a component added
  after upgrading the gem does not raise `NoMethodError`. Components you copied
  earlier keep the English written into them until you copy them again.
- The performance budgets for component source (140000 -> 150000 bytes) and for
  the Stimulus payload (56000 -> 56500) are raised, with the reasons recorded in
  `config/performance_budgets.yml`. The per-file caps and the gzip total are
  unchanged.
- **`NativeSelectComponent` defaults to its own chevron instead of the browser's
  arrow** (`native_arrow: false`). A select was the one control in the library
  with no visible state: the OS arrow cannot be styled or animated, so nothing
  distinguished an open select from a closed one. The custom chevron already
  existed, rotated on focus, and had to be asked for by name — which meant
  nobody got it. Pass `native_arrow: true` to opt back in; worth doing on
  mobile, where the OS renders its own picker anyway.

  The component marker moves with it. In custom-arrow mode
  `data-senren-component="native_select"` sits on the wrapper that positions the
  chevron, and the `<select>` underneath still carries the name, the controller
  and the selection. Anything selecting on `select[data-senren-component]` needs
  updating.
- `InviteMemberDialogComponent` renders its role field through
  `NativeSelectComponent` rather than a hand-written `<select>` whose styling
  had been copied out of it — which is why it silently missed everything that
  component gained afterwards, the chevron included.

### Fixed

- `FormComponent` yields the Rails form builder, as `docs/components.md` always
  said it did. The block received the component instead, and because a
  component is an `ActionView::Base` the documented `f.text_field :title,
  class: "x"` did not raise: it reached the template-level helper and rendered
  `name="title[{class: "x"}]"`, so the field posted under a name no controller
  reads. Blocks that never touch `f`, and `with_content`, render as before.

  Code that treated `|f|` as the component breaks: `f.tag`, `f.link_to`,
  `f.render`, `f.model` and `f.url` now raise `NoMethodError` on the builder.
  Call those on the view instead. A `FormComponent` rendered with neither a
  block nor content now renders an empty `<form>` rather than raising.
- `TopNavComponent`'s default variant had no background. Its class,
  `bg-[hsl(var(--senren-background))/0.88]`, put the alpha outside `hsl()`,
  inside the brackets, so Tailwind emitted `hsl(...)/0.88` verbatim and the
  browser dropped it as an invalid colour: the sticky header was transparent
  over scrolled content. It is now `bg-[hsl(var(--senren-background)/0.88)]`,
  the form every other translucent class in the library uses, and a test bans
  the broken shape across `templates/` and `lib/`.
- `TableComponent` and `DataTableComponent` are now `relative`, so their
  `sr-only` caption is positioned inside the component. `sr-only` is
  `position: absolute`, and with nothing positioned the caption escaped the
  components' own overflow clipping and was placed against the page. In a
  fixed-height shell whose `<main>` scrolls, a captioned table below the fold
  made the document taller, and the window scrolled into blank space under a
  shell that should never scroll.
- `DataTableComponent` no longer breaks a `<td>` whose cell holds markup. The
  cell value was written straight into `data-sort-value="..."`, and a badge,
  link or anything else built with `tag` or `render` is a SafeBuffer, which ERB
  does not escape: the markup's first `"` closed the attribute, the rest became
  junk attributes, and every row sorted on the same `<span class=` fragment.
  The sort value is now the cell's decoded text, escaped once, so a cell
  showing `R&D` sorts as `R&D`. Plain-string and numeric cells are unchanged.
- `ThemeToggleComponent` rendered the letters `O`, `D` and `L` where an icon
  belongs. It now ships sun and moon SVGs and swaps which is hidden, so the
  correct icon is in the HTML the server sends rather than written in by
  JavaScript after first paint. The icon names the theme the click switches to,
  matching the label.
- `AccordionComponent` showed a static `+` and snapped open. It now has a
  chevron that turns over, driven by `aria-expanded` so the icon cannot drift
  out of step with the state assistive technology is told, and the panel
  animates via `grid-template-rows: 0fr → 1fr` — which reaches the content's own
  height without measuring it in JavaScript.

  The `hidden` attribute is kept through the animation. Content that is visually
  collapsed but present is still focusable and still read aloud, so the
  controller drops `hidden` before opening and restores it once the closing
  transition ends, with a timer for the cases where `transitionend` never
  arrives: reduced motion, an off-screen element, an already-collapsed panel.

## [0.3.0] — 2026-09-01

### Breaking

- **`ButtonComponent` no longer emits `type="button"` by default.** The
  attribute is omitted, so a button inside a form submits it, which is what
  plain HTML does and what everyone expects. The old default silently swallowed
  submits: a form's own submit button did nothing, with no error anywhere to
  explain it. The new default fails the other way, and loudly — a trigger that
  should not submit now has to say so.

  **Migrate:** pass `type: :button` to any button that must not submit — overlay
  triggers, menu triggers, a dialog's Cancel. Everything inside a form that is
  meant to submit needs no change and starts working. Buttons outside a form
  are unaffected either way.

  ```erb
  <%= render(Senren::ButtonComponent.new(type: :button)) { "Open dialog" } %>
  ```

### Fixed

- Every component now merges a caller's `class:` and `data:` instead of
  dropping them. Splatting `**html_attrs` after the computed values replaced
  them outright, so `class:` erased the component's own variant and size
  styling and `data:` erased its `data-senren-component` marker.
- For the eight wrapper components — dialog, alert dialog, sheet, popover,
  dropdown menu, context menu, hover card, tooltip — a caller's class now lands
  on the panel, which is the element they style, not on the empty root, where it
  sat in the DOM doing nothing.

  This makes the extension point reachable; it does not make it resolve
  conflicts. `class_name: "max-w-sm"` on a dialog emits
  `class="max-w-lg max-w-sm"` and both declarations stay live, so which one
  applies is decided by the order Tailwind emits them, not by the order of the
  attribute. Measured against a real build: `max-w-sm` wins (narrowing works),
  `max-w-2xl` loses (widening is a silent no-op). Use Tailwind's important
  modifier — `class_name: "max-w-2xl!"` — for an override that does not depend
  on emit order.
- `data-controller` and `data-action` are appended rather than substituted, so
  attaching your own Stimulus controller to a Senren component no longer unbinds
  the component's own.
- A caller's `data-controller` or `data-action` that repeated one of the
  component's own tokens was appended rather than deduplicated:
  `data: { controller: "a senren--popover" }` produced
  `"a senren--popover senren--popover"`. Stimulus reads that list literally, so
  the controller connected twice and every action fired twice — a toggle opened
  and immediately closed. Tokens are deduplicated individually now.
- `data:` written with String keys (`data: { "action" => ... }`) is merged the
  same as Symbol keys. The Symbol-only read meant a dropdown item passing a
  String key lost close-on-click and arrow-key handling.
- A dropdown item's `class:` is merged rather than substituted. Losing the hover
  style was cosmetic; losing `focus:bg-` removed the only indication a keyboard
  user has of where they are in the menu.
- Sheet's scrolling body no longer clips focus rings.
- Dialog, sheet, and the invite-member dialog close on an overlay click.
- `method:` on a dropdown item reaches Turbo. It was passed to `link_to` as a
  rails-ujs option, which Rails 7 dropped, so it had rendered an inert `method`
  attribute since the library began targeting Rails 7.1.
- Card footer spacing, and pagination now wraps.
- `CartComponent` accepted `remove_url:` per item, normalised it, and wrote it
  nowhere. Removal is client-side and dispatches `senren--cart:removed` for the
  application to act on, so the URL was the one thing the listener needed and
  the only thing it could not get. It is emitted as `data-remove-url` on the
  line and carried in the event detail, omitted entirely when not supplied, and
  passed through `safe_url` like every other URL the library renders.
- `senren_themes.css` shipped with its ERB examples unrendered, so the header
  comment showed `<%%=` where it means `<%=`. The assertion guarding against that
  named a single file, so the property held exactly where someone had thought to
  look; it now runs over everything the generator writes.

### Documentation

- The palette presets shipped in 0.2.0 with no mention in the README, the docs,
  or the generated conventions file. All three now cover them, including the
  load-order constraint: `senren_themes.css` must be linked after `senren.css`
  or the theme silently does nothing.

### Internal

- ERB linting names every linter it runs. Thirteen were running against nine
  named in the config; eight formatting linters had been on by default and
  unrecorded. A test now fails if an upgrade adds a fourteenth.
- `bin/ci` and the GitHub workflow call `erb_lint` rather than the deprecated
  `erblint` shim.
- json bumped to 2.21.2 for CVE-2026-71847.
- Herb now lints the markup, and the 32 offenses it found in shipped templates
  are fixed. It was adopted after a developer reported warnings in their editor
  that none of this project's gates produced — RuboCop covered the Ruby, Biome
  the Stimulus controllers, erb_lint the ERB structure, and the HTML itself had
  no linter at all. Pinned to 0.10.3 in `.herb.yml`, and wired into `bin/ci`,
  `bin/lint-fix` and the GitHub workflow.

  Most of what it found is invisible in the rendered page but visible in the
  editor of anyone who installs these components, since `senren:add` copies them
  into their repository. Fifteen component roots moved from
  `<div <%= tag.attributes(**root_attrs(...)) %>>` to `tag.div(...) do`, which
  is what the overlays already used; seven conditional boolean attributes moved
  from `<%= "hidden" unless expanded %>` to `<% unless expanded %>hidden<% end %>`;
  three raw `<img>` tags became `image_tag`; breadcrumb stopped writing its whole
  `<nav>` once per branch; and an empty `aria-activedescendant` is gone.

  Nothing changes visually, but the markup string is not identical: rendering
  all 64 components before and after produces 35 differing lines — 26 of them
  whitespace and indentation, 6 the attribute order and self-closing slash that
  `image_tag` emits, 2 the `href` moving to the front of an `<a>`, and 1 the
  removed empty attribute. If you assert on exact markup anywhere, those
  snapshots need regenerating. If you have already installed these components,
  nothing in your application changes at all — the new markup arrives only if
  you re-run `senren:add --force`.

## [0.2.0] — 2026-08-02

A hardening release. Most of it came out of an adversarial review of the whole
library; each item below was reproduced by running it before being fixed, and
pinned by a test that was watched failing first.

### Upgrading

Four changes alter existing behaviour. None requires a code change in your app,
but read these before upgrading:

- **`class:` now merges instead of replacing.** Previously
  `ButtonComponent.new(variant: :primary, class: "mt-2")` rendered
  `class="mt-2"` and dropped the variant and size styling entirely. It now
  renders both. If you worked around the old behaviour by re-specifying every
  utility, you can stop.
- **DOM ids are derived from component arguments, not random.** Ids are now
  stable across renders, which is what makes Turbo morphing, fragment caching,
  and ETags work. If you hard-coded a generated id in a test or a stylesheet,
  it will have changed.
- **Booting with `app/components` on the asset load path now fails in
  production.** See *Security* below. If you added that line for sidecar
  assets, point it at `app/components/assets` instead.
- **`Senren::Rails::Installer` was removed.** It had no callers, and copying
  `.tt` templates without rendering them would have written raw ERB into a host
  app. `senren:install` is the supported path.

### Added

- `CartComponent` and `ProductCardComponent`, plus a `storefront` recipe.
  The cart keeps a live subtotal and quantity steppers client-side and
  announces changes with `senren--cart:changed`; the product tile submits a
  form and ships no JavaScript, so listing pages stay light.
- `lib/senren-ui.rb`, so `gem "senren-ui"` loads the engine without a
  `require:` option. Previously that form silently loaded nothing — no engine,
  no rake tasks, and no asset guard — while the generator kept working.
- On-demand Stimulus loading, installed rather than documented.
  `senren:install` switches `controllers/index.js` to `lazyLoadControllersFrom`
  and adds `preload: false` to the controllers pin. It leaves a customised
  `index.js` or a non-importmap app alone and reports what it did.
- `bin/watch`, which syncs template edits into the local preview app and
  reloads the browser. Development-only; nothing ships to host apps.
- A Ruby 3.2–3.4 × Rails 7.1–8.1 test matrix, so the versions the gemspec
  claims are the versions that are proved.

### Changed

- Overlay components (dialog, sheet, popover, dropdown, context menu, alert
  dialog) drive their state through Stimulus values instead of writing to the
  DOM directly, so state survives Turbo morphs.
- `--client` / `--no-client` applies only to the components you name.
  It used to apply to the whole dependency closure, so
  `senren:add context_menu --no-client` also stripped `dropdown_menu`'s
  controller and the installed menu silently never opened.
- `.senren/skill.md` describes what was actually installed. It previously
  reported the registry default, naming controller files that were not on disk.
- `.senren/registry.yml` refreshes on every install instead of drifting from
  the gem after the first one.
- Rake helpers live in `SenrenRakeArgs` rather than as top-level methods on
  `Object`, and argument scanning stops at the next rake task —
  `rake 'senren:add[button]' db:seed` no longer tries to install `db:seed`.
- Documentation states the library's scope without characterising other
  ecosystems.

### Security

- **Component source could be published in production.** With
  `config.assets.paths << Rails.root.join("app/components")` — a line that
  circulates as ViewComponent sidecar-asset guidance — Propshaft resolved every
  component `.rb` and `.html.erb` as an asset, `assets:precompile` copied them
  into `public/assets`, `.manifest.json` listed each by name, and the digested
  URL returned Ruby source with `HTTP 200`. A boot check now raises in any
  deployed environment and warns in development. Sidecar assets in their own
  directory are unaffected.
- **The installer could write outside the application root.** A checkout
  shipping `app/components/senren` as a symlink redirected copied files, and
  the agent-adapter writers read their destination before rewriting it, so
  content outside the checkout was modified too. All writes now go through one
  containment layer that resolves symlinks, covers dangling links, and refuses
  only paths that leave the root — an in-repo symlink such as
  `ln -s AGENTS.md CLAUDE.md` keeps working.
- **`FormComponent#url` and `AvatarComponent#src` were unsanitised.** The first
  reaches `form_with`'s action, where a protocol-relative URL sends every field
  and the CSRF token off-origin. Both now use the same URL policy as the rest
  of the library, and a property test covers every component rather than a list
  of known ones.
- Rich-text paste is sanitised, and the two URL policies (markup versus typed
  input) are separated so neither can promote a relative path to another origin.
- Five dependency advisories resolved, and `bundler-audit` is now a CI gate.

### Fixed

- `senren:doctor` reported success unconditionally.
- Marker-managed files could be corrupted by generated content containing
  regexp backreferences, and could inject their own markers.
- `TypographyComponent`, `SeparatorComponent`, and `AspectRatioComponent`
  raised on `.new` without an explicit variant.
- `data:` passed to any component dropped its `data-senren-component` marker.
- Eight components produced a new DOM id on every render.
- `date_picker` lost its height to a fused CSS class.
- Stimulus controllers no longer leak timers or document-level listeners across
  Turbo navigations.
- Checkbox, radio, and switch controls are reachable by their accessible name.

## [0.1.6] — 2026-06-09

### Added

- Local preview app now seeds the full registered Senren component set and renders an exhaustive component kitchen sink.

### Changed

- `bin/seed_preview` is now the canonical local preview seed command and targets `.local/preview`.
- `bin/seed_preview` writes a local-path gem entry that works for custom preview roots.
- `.rubocop.yml` target Ruby version now matches the gem runtime floor required by ViewComponent 4.x.

### Fixed

- `safe_url` now accepts same-origin relative URLs such as `?page=:page`, `./settings`, and `settings` while still rejecting unsafe schemes and hosts.
- `ComponentCopier` applies the same URL rules when patching existing host apps.
- Local preview layout keeps the Tailwind browser compiler enabled so the preview renders correctly out of the box.

## [0.1.5] — 2026-05-03

### Added

- Multi-agent instruction sync system (`AgentRulesWriter`). A single
  source-of-truth file (`.senren/agent-rules.md`) plus marker-managed
  adapter files for Codex (`AGENTS.md`), Claude (`CLAUDE.md`),
  Copilot (`.github/copilot-instructions.md`), and Cursor
  (`.cursor/rules/senren.mdc`).
- New rake task `senren:agents:sync`.
- Plan 014 and Plan 015 documentation.

### Changed

- `LlmsWriter` is now a thin backward-compatible wrapper that delegates
  to `AgentRulesWriter`. No more `public/llms*.txt` generation.
- `senren:llms:generate` kept as deprecated alias.
- `Doctor` checks now validate agent instruction files instead of
  `public/llms*.txt`.
- Doctor `run!` refactored into `runtime_checks` + `installation_checks`.
- Install generator no longer creates `public/` directory.

### Fixed

- Deprecated `senren:llms:generate` task now passes `registry:` kwarg
  consistently with all other call sites.
- Release checklist items updated to reflect agent sync system.
- Test assertion style standardized on Minitest-native `refute`.

## [0.1.4] — 2026-05-02

### Fixed

- Gem metadata now exposes both public links correctly:
  - `homepage`/`homepage_uri` points to [senren-ui.dev](https://www.senren-ui.dev)
  - `source_code_uri` and `changelog_uri` point to GitHub.

## [0.1.3] — 2026-05-02

### Added

- Documentation site deployed at [senren-ui.dev](https://www.senren-ui.dev).
- Gem homepage now points to the live docs site.

## [0.1.2] — 2026-05-02

### Fixed

- Progress component no longer paints variant background on the full root
  container. Variant color is now applied only to the indicator fill bar.
- Improved progress visuals by separating track/fill styling more clearly
  (`h-2.5` track) and using smoother fill-width transition
  (`transition-[width] duration-300 ease-out`).

## [0.1.1] — 2026-05-02

### Added

- Initial gem skeleton, engine, and version constant.
- Component registry (`registry/components.yml`, `groups.yml`,
  `recipes.yml`) covering all Phase 1–6 components from the master plan.
- Library classes: `Registry`, `HostPaths`, `ComponentCopier`,
  `SkillWriter`, `LlmsWriter`, `Installer`, `Doctor`.
- Generators: `senren:install`, `senren:component` (with `--client`).
- Rake tasks: `senren:add`, `senren:skill:sync`, `senren:llms:generate`,
  `senren:doctor`.
- Phase 1–3 components fully implemented as ViewComponents.
- Phase 4–6 components scaffolded as registered stubs.
- Stimulus controllers for all interactive Phase 3 components.
- Tailwind design-token stylesheet (`senren.css`) with light/dark.
- Centralized `.senren/skill.md` system with preserved user-region.
- `public/llms.txt` and `public/llms-full.txt` generation.
- A Rails dogfooding app for local-path gem integration.
- Bun-based JS tooling for Stimulus templates:
  - `bun run controllers:syntax`
  - `bun run controllers:lint`
  - `bun run controllers:lint:fix`
  - `bun run controllers:check`
- Biome lint configuration (`biome.json`) scoped to
  `templates/controllers/**/*.js`.

### Changed

- `SidebarComponent` template + Stimulus controller now support robust
  compact/expanded syncing:
  - hides brand/footer in compact mode
  - shows link initials in compact mode and full labels in expanded mode
  - uses a hamburger icon toggle with `aria-expanded`
  - applies smoother width/label transition behavior
- `TabsComponent` template + Stimulus controller now use
  `data-state="active|inactive"` for tab and panel state, so header active
  styling updates correctly after client-side tab switches.

### Fixed

- Docs-site feedback issues now resolved at gem template level (not app-only):
  sidebar compact truncation UX and tabs header active-state mismatch.

## [0.1.0] — 2026-04-27

First tagged release once the Unreleased entries are validated end-to-end
against the project dogfooding app per `plans/011_release_checklist.md`.
