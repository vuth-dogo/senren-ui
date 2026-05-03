# 2026-05-03 21:52 — Multi-agent rules sync and marker-safe adapters

## Summary

- Replaced public llms generation with a private multi-agent sync model.
- Added one source-of-truth file (`.senren/agent-rules.md`) and adapter outputs
  for Codex, Claude, Copilot, and Cursor.
- Implemented marker-safe updates so existing project instruction files are not
  overwritten outside Senren-managed blocks.

## Implementation notes

- Added `Senren::Rails::AgentRulesWriter` to generate:
  - `.senren/agent-rules.md`
  - `AGENTS.md`
  - `CLAUDE.md`
  - `.github/copilot-instructions.md`
  - `.cursor/rules/senren.mdc`
- Adapter files are updated via
  `<!-- senren:agent:start -->` / `<!-- senren:agent:end -->`.
- Updated install/add/skill sync flows to run agent sync.
- Added `senren:agents:sync` task and kept `senren:llms:generate` as a
  deprecated compatibility alias.
- `LlmsWriter` now delegates to `AgentRulesWriter`.
- `Doctor` checks were switched from `public/llms*.txt` to the new agent files.
- Refactored `Doctor#run!` into grouped checks to satisfy RuboCop ABC metrics.

## Plan updates

- Added `plans/014_multi_agent_instruction_sync.md`.
- Marked `plans/005_llms_system.md` as superseded by Plan 014.

## Verification

- `bundle exec rubocop`
- `bundle exec rake test`
- `bun run controllers:check`
