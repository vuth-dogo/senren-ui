# Plan 000 — Project Overview

## Purpose

Define the canonical, one-page understanding of what Senren UI is, who it
serves, and the constraints every other plan must respect. This document is
the source of truth that every later plan refers back to.

## Scope

- The `senren-ui` gem source in `senren-rails/`.
- The `apps/todolist` real Rails dogfooding app.
- The AI-agent surface (`.senren/skill.md`, `public/llms.txt`,
  `public/llms-full.txt`).
- The component registry, generators, and rake tasks.

Out of scope for v0.1:

- A standalone JavaScript framework or React/Vue/Alpine bridges.
- A hosted documentation site beyond a basic dummy/demo Rails app.
- A package distribution channel other than RubyGems + local path gem.

## Decisions

1. Senren is a **hybrid gem + source-copy** UI library. The gem ships
   generators and a registry; component source is copied into the host app.
2. Server-rendered HTML via ViewComponent is the default rendering model.
3. Hotwire (Turbo + Stimulus) is the only client runtime. No React, Vue,
   Alpine, or external state framework.
4. TailwindCSS is the styling layer, with semantic CSS variables.
5. AI-agent documentation is **centralized** in `.senren/skill.md`, grouped
   by logical category. One file per component is explicitly rejected.
6. The workspace contains both the gem and a real Rails app
   (`apps/todolist`). `test/dummy` alone is not sufficient validation.
7. Planning (`/plans`) and history (`/history`) are mandatory, not optional.
8. Senren v0.1 must scaffold every component listed in section 21 of
   `master_prompt.md`, even if some are stubbed and clearly marked.

## Files to create

- This file.
- All other `plans/00X_*.md` files in this directory.
- `history/<timestamp>-initial-planning.md`.

## Files to modify

None at this stage. This is a planning document.

## Expected behavior

After reading this plan, a contributor (human or AI agent) should be able
to answer:

- What is Senren UI?
- What technologies does it use and explicitly forbid?
- Where do component files live?
- Where is the AI-agent guidance located?
- Why is `apps/todolist` part of the workspace?

## Test strategy

Documentation-only. Verified by:

- Cross-referencing every "must" statement here against `master_prompt.md`.
- Ensuring no later plan contradicts the decisions above.

## Acceptance criteria

- [ ] All eight standard sections present.
- [ ] All decisions traceable to `master_prompt.md`.
- [ ] No mention of forbidden technologies (React, Vue, Alpine, external
      state frameworks) as part of the implementation.
- [ ] Document fits on a single screen of context for an AI agent
      (under ~120 lines).
