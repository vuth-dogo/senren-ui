# 2026-10-03 00:20 - FormComponent Yields The Builder It Promised

## Goal

`docs/components.md` says FormComponent "yields a Rails form builder (`|f|`)"
and shows `f.text_field :title`. It did not. Reported from an app whose file
upload posted nothing.

## The bug

The template was:

```erb
<%= form_with(...) do |f| %>
  <%= content || capture(f, &Proc.new) %>
<% end %>
```

`content` is ViewComponent's, and it calls the render block with the
**component** as its argument. When a block was given, `content` was never nil,
so the builder was never handed over. The fallback was dead code twice over:
unreachable, and `Proc.new` without a block raises on Ruby 3.

The failure was silent. A component is an `ActionView::Base`, so it answers the
template-level `text_field(object_name, method, options)`. `f.text_field
:title, class: "x"` treated `:title` as the object name and the options hash as
the method, and rendered `name="title[{class: "x"}]"`. The page looked right
and submitted; the controller got nothing under `title`.

Callers that only rendered Senren input components inside the block never
touched `f`, which is the only reason the bug went unnoticed.

## Changes

- `templates/components/form/form_component.rb`: `render_in` keeps the
  caller's block; `form_body(builder)` calls it with the builder from
  `form_with`. Same precedence as ViewComponent's `content` (a block wins over
  `with_content`), and the same caller virtual path, so relative `t('.key')`
  inside the block resolves as before. `with_captured_virtual_path` and
  `@old_virtual_path` exist in every ViewComponent 4 checked (4.5, 4.11, 4.12,
  4.15).
- `form_component.html.erb`: `<%= form_body(f) %>`.
- `test/integration/form_builder_yield_test.rb`: builder class, field names
  for `text_field`, `file_field` and a model form, fields inside the `<form>`,
  and the two paths that must not change (block without `|f|`,
  `with_content`).
- `CHANGELOG.md`: Unreleased / Fixed.

`docs/components.md` needed no change: it described the intended behaviour,
which is now the real one.

## Rejected

Delegating the builder's methods from the component to `f`. It recurses:
`FormBuilder#text_field` calls `@template.text_field(...)`, and `@template` is
the component.

## Validation

- New test on the unfixed templates: 7 runs, 3 failures, 2 errors
  (`"title[{placeholder: \"T\", class: \"x\"}]"` where `"title"` was expected).
- Same test with the fix: 7 runs, 13 assertions, 0 failures.
- `bin/ci`: 8 of 9 gates pass (206 unit, 70 integration, 29 system runs, 0
  failures; RuboCop, ERB lint, HTML lint, JS, performance clean). The
  dependency audit fails on rubyzip 3.3.1 (CVE-2026-85396), which fails the
  same way on `origin/main` and is not touched here.
