# Changelog

All notable changes to `senren-ui` are recorded here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
v0.x is a pre-stable line: minor bumps may break things; patch bumps are
bug fixes only.

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
