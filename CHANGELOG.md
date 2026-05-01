# Changelog

All notable changes to `senren-ui` are recorded here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
v0.x is a pre-stable line: minor bumps may break things; patch bumps are
bug fixes only.

## [Unreleased]

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
- `apps/todolist` Rails app dogfooding the gem via local path.

## [0.1.0] — TBD

First tagged release once the Unreleased entries are validated end-to-end
in `apps/todolist` per `plans/011_release_checklist.md`.
