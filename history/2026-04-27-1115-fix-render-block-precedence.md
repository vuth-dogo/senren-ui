# Fix: Empty Senren components in Todolist views (block precedence bug)

## Time

2026-04-27 11:15 UTC

## Symptom

`Todos#index` rendered the layout, cards, badges, search box, and selects, but **all text was missing**: empty `<h1>`, empty button anchors, empty badge spans. Screenshot showed colored badge fills with no labels.

## Cause

In Ruby, the `{ ... }` block has higher precedence than `do ... end`, so:

```erb
<%= render Senren::TypographyComponent.new(variant: :h1) { "Todos" } %>
```

is parsed as:

```ruby
render(Senren::TypographyComponent.new(variant: :h1) { "Todos" })
```

The block attaches to `.new`, not `render`. ViewComponent therefore receives **no content**, and the component template emits an empty element (`<h1 ...></h1>`).

This pattern was used throughout `apps/todolist/app/views/todos/*.html.erb`.

## Fix

Wrapped the receiver in parentheses so the block attaches to `render`:

```erb
<%= render(Senren::TypographyComponent.new(variant: :h1)) { "Todos" } %>
```

Files updated:

- `apps/todolist/app/views/todos/index.html.erb`
- `apps/todolist/app/views/todos/_todo.html.erb`
- `apps/todolist/app/views/todos/show.html.erb`
- `apps/todolist/app/views/todos/_form.html.erb`
- `apps/todolist/app/views/todos/new.html.erb`
- `apps/todolist/app/views/todos/edit.html.erb`
- `senren-rails/README.md` (matching example)

## Prevention

Added rule 7 to `lib/generators/senren/install/templates/conventions.md.tt`:

> **Render with parens when passing inline content blocks.** Ruby block precedence makes `render Senren::Foo.new(args) { "bar" }` attach the block to `.new`, **not** to `render`, producing an empty component.

Existing apps' `.senren/conventions.md` was refreshed from the new template.

## Verification

```bash
bin/rails test
# 12 runs, 54 assertions, 0 failures, 0 errors, 0 skips

bin/rails runner /tmp/check_render.rb
# status: 200
# has h1 Todos: true
# has '+ New todo' button: true
# has 'Pending' badge: true
# has 'Overdue' badge: true
# has 'Draft Q3 OKRs' title: true
```
