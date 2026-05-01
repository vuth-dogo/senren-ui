# 2026-04-29 00:05 - SaaS Blocks promoted

## Summary

- Promoted all SaaS Blocks from visible stubs to functional ViewComponent
  templates:
  AppShell, TopNav, PageHeader, EmptyState, StatCard, SettingsSection,
  DataTable, FilterBar, SearchInput, BulkActionBar, TeamMemberList,
  InviteMemberDialog, BillingPlanCard, ApiKeyField, and ActivityFeed.
- Added real APIs for structured data, slots, actions, and composed
  primitives while preserving `data-senren-component` roots.
- Added Stimulus behavior for sortable data tables, invite dialogs, and
  API key reveal/copy controls.
- Synced the docs site copies, preview partials, app registry mirror,
  `.senren/skill.md`, and generated `llms` files.

## Scope note

Rich Content components remain stubbed: Carousel, Codeblock, Command, and
RichTextEditorLite.

## Verification

- `bundle exec rake test` in `senren-rails`
  - `15 runs, 1049 assertions, 0 failures, 0 errors, 0 skips`
- `node --check` for the promoted Stimulus controllers in both
  `senren-rails/templates/controllers` and `apps/site/app/javascript/controllers/senren`
- `bin/rails tailwindcss:build` in `apps/site`
- Rails smoke over all 15 SaaS component pages:
  - `saas_pages=15 failures=0`
