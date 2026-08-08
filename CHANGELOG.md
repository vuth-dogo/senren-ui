# Changelog

All notable changes to `senren-ui` are recorded here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
v0.x is a pre-stable line: minor bumps may break things; patch bumps are
bug fixes only.

## [Unreleased]

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
  on the panel, which is the element they style, not on the empty root. It used
  to be applied to the root, where it sat in the DOM doing nothing:
  `class_name: "max-w-2xl"` on a dialog left the panel at `max-w-lg`.
- `data-controller` and `data-action` are appended rather than substituted, so
  attaching your own Stimulus controller to a Senren component no longer unbinds
  the component's own.
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
