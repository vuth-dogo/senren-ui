# Plan 006 — Tailwind Design Tokens

## Purpose

Define the semantic design-token system that all Senren components
must use, and the CSS layer that hosts the token values.

## Scope

- `app/assets/stylesheets/senren.css` (host app, copied at install).
- Token naming convention.
- Light and dark theme variables.
- The Tailwind config additions, if any.

## Decisions

1. Tokens are CSS custom properties in HSL channels (no `hsl()`
   wrapper). This matches shadcn-style tokens and keeps Tailwind
   `bg-[hsl(var(--token))]` ergonomic.
2. Token names use the `--senren-` prefix to avoid collision:
   `--senren-background`, `--senren-foreground`, `--senren-primary`,
   `--senren-primary-foreground`, `--senren-muted`,
   `--senren-muted-foreground`, `--senren-border`,
   `--senren-destructive`, `--senren-destructive-foreground`,
   `--senren-radius`.
3. Components reference tokens via Tailwind utilities like
   `bg-background`, `text-foreground`, `border-border`. The Tailwind
   config registers these as semantic colors that resolve to
   `hsl(var(--senren-...))`.
4. Senren ships **one** stylesheet, `senren.css`, with `:root` and
   `.dark` variable blocks. No JS-driven theme management is
   required; consumers can use `class="dark"` on `<html>`.
5. Components must not hard-code `gray-*`, `slate-*`, or arbitrary
   colors. Linter/test verifies this.
6. `--senren-radius` is the single source of truth for border radius.
   Tailwind's `rounded-md` etc. are aliased to compute from it.

## Files to create

```
senren-rails/lib/generators/senren/install/templates/senren.css.tt
senren-rails/templates/components/_tokens_README.md
senren-rails/docs/tokens.md
senren-rails/test/components/tokens_lint_test.rb
```

## Files to modify

- All component templates under `templates/components/` use semantic
  utilities only.
- Host app's Tailwind config is updated by the install generator, or
  the install generator leaves a clear instruction if Tailwind is
  configured via `tailwind.config.js` rather than the Rails
  `tailwindcss-rails` gem.

## Expected behavior

- After `senren:install`, `app/assets/stylesheets/senren.css` exists
  with both light and dark token blocks.
- All copied components render with consistent colors and radius.
- Switching `<html class="dark">` flips colors without code changes.

## Test strategy

- Token lint test: scan `templates/components/**/*.html.erb` for any
  hard-coded `gray-`, `slate-`, `zinc-`, `red-`, `blue-` etc. and
  fail if found outside an allowlist.
- Snapshot test: `senren.css` content is byte-stable across runs.
- Visual smoke test in `apps/todolist`: light and dark mode toggle.

## Acceptance criteria

- [ ] `senren.css` exists and contains both `:root` and `.dark`.
- [ ] No hard-coded color utilities in component templates.
- [ ] Dark mode works in `apps/todolist`.
- [ ] Token names documented in `docs/tokens.md`.
