# Plan 014 — Multi-agent instruction sync (no public llms)

## Purpose

Replace `public/llms*.txt` generation with a safer multi-agent instruction
system that works with Copilot, Codex, Claude, and Cursor while preserving any
existing project instructions.

## Scope

- `.senren/agent-rules.md` as single source of truth.
- Adapter files:
  - `AGENTS.md` (Codex)
  - `CLAUDE.md` (Claude)
  - `.github/copilot-instructions.md` (Copilot)
  - `.cursor/rules/senren.mdc` (Cursor)
- Marker-safe generation behavior.
- Install/task/doctor/docs rewiring.
- Compatibility path for legacy `senren:llms:generate`.

## Decisions

1. Generated agent instructions are **not** served from `public/`.
2. Adapter files are managed by marker blocks only:
   `<!-- senren:agent:start -->` … `<!-- senren:agent:end -->`.
3. Existing content outside markers is preserved.
4. `senren:agents:sync` is the primary command; `senren:llms:generate`
   remains as deprecated alias.
5. `LlmsWriter` delegates to `AgentRulesWriter` for backward compatibility.

## Files created

- `lib/senren/rails/agent_rules_writer.rb`
- `test/agent_rules_writer_test.rb`
- `test/llms_writer_test.rb`

## Files modified

- `lib/senren/rails/host_paths.rb`
- `lib/senren/rails/doctor.rb`
- `lib/senren/rails/installer.rb`
- `lib/senren/rails/llms_writer.rb`
- `lib/senren/rails.rb`
- `lib/tasks/senren.rake`
- `lib/generators/senren/install/install_generator.rb`
- `lib/generators/senren/install/templates/conventions.md.tt`
- `bin/seed_site.rb`
- `bin/seed_todolist.rb`
- `README.md`

## Expected behavior

- Install/add/skill sync regenerate `.senren/agent-rules.md` and adapters.
- Re-running sync is idempotent and does not duplicate marker blocks.
- Pre-existing instruction text in adapter files remains intact outside markers.
- Doctor validates agent instruction files instead of `public/llms*.txt`.

## Test strategy

- Unit test: create all agent files and ensure no `public/llms*.txt`.
- Unit test: replace marker block without destroying surrounding content.
- Unit test: append marker block when file has no markers.
- Unit test: `LlmsWriter` compatibility delegation.
- Lint and tests:
  - `bundle exec rubocop`
  - `bundle exec rake test`
  - `bun run controllers:check`

## Acceptance criteria

- [x] Multi-agent files generated from a single source file.
- [x] Marker-safe updates preserve non-generated user content.
- [x] No public llms file generation in new flow.
- [x] Legacy llms task remains available as compatibility alias.
