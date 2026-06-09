# Senren Components Guide

This guide covers the form-related components in detail, with runnable examples
and explicit guidance on common pitfalls.

---

## FormComponent

Wraps `form_with` with Senren semantic tokens and consistent spacing.

### Key behavior

- **Yields a Rails form builder** (`|f|`) — use `f.text_field`, `f.select`, etc.
  inside the block just like a normal Rails form.
- **`method:` defaults to `nil`** — Rails will infer `:post` for new records and
  `:patch` for persisted records. Only pass `method:` explicitly when you need to
  override this (e.g., `method: :delete`).
- **`model: nil` is safe** — model-less forms (login, search, password reset)
  work without passing a model.

### Examples

#### Basic model form (create)

```erb
<%= render(Senren::FormComponent.new(model: @post, url: posts_path)) do |f| %>
  <%= render(Senren::LabelComponent.new(for_field: "title", variant: :required)) { "Title" } %>
  <%= f.text_field :title, class: "senren-input" %>
  <%= render(Senren::ButtonComponent.new(variant: :primary, type: :submit)) { "Create" } %>
<% end %>
```

#### Edit form (Rails infers PATCH automatically)

```erb
<%= render(Senren::FormComponent.new(model: @post, url: post_path(@post))) do |f| %>
  <%= render(Senren::LabelComponent.new(for_field: "title")) { "Title" } %>
  <%= f.text_field :title, class: "senren-input" %>
  <%= render(Senren::ButtonComponent.new(variant: :primary, type: :submit)) { "Update" } %>
<% end %>
```

#### Model-less form (login)

```erb
<%= render(Senren::FormComponent.new(url: session_path)) do |f| %>
  <%= render(Senren::InputComponent.new(name: "email", type: "email", placeholder: "you@example.com")) %>
  <%= render(Senren::InputComponent.new(name: "password", type: "password")) %>
  <%= render(Senren::ButtonComponent.new(variant: :primary, type: :submit)) { "Sign in" } %>
<% end %>
```

> **Warning**: Do NOT pass `method: :post` on edit forms for persisted models.
> Rails needs `method:` to be nil to infer PATCH, otherwise you'll get
> `No route matches [POST] "/resource/:id"`.

---

## InputComponent

### ⚠️ InputComponent vs `form.text_field`

**`InputComponent` renders its own `<input>` tag.** It is a **replacement** for
`form.text_field`, not an add-on. Do not combine them.

#### ✅ Do

```erb
<%# Option A: Use InputComponent standalone %>
<%= render(Senren::InputComponent.new(name: "email", type: "email")) %>

<%# Option B: Use Rails form builder with plain classes %>
<%= f.text_field :email, class: "your-input-classes" %>
```

#### ❌ Do NOT

```erb
<%# WRONG: This renders two inputs %>
<%= render(Senren::InputComponent.new(name: "email")) do %>
  <%= f.text_field :email %>
<% end %>
```

### Required params

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String/Symbol | **Yes** | — | Input `name` attribute |
| `type` | String | No | `"text"` | HTML input type |
| `value` | String | No | `nil` | Pre-filled value |
| `placeholder` | String | No | `nil` | Placeholder text |
| `id` | String | No | auto | Defaults to parameterized `name` |
| `variant` | Symbol | No | `:default` | `:default` or `:error` |
| `size` | Symbol | No | `:md` | `:sm`, `:md`, or `:lg` |

### File inputs

File inputs automatically get styled button treatment:

```erb
<%= render(Senren::InputComponent.new(name: "avatar", type: "file")) %>
```

The file selector button uses a segmented style with a divider, semantic surface
color, and pointer cursor — no additional classes needed.

### Date/time inputs

Native date and datetime-local inputs work correctly. The component intentionally
omits `display: flex` from base styles because it breaks browser-native
date/time picker UI on some engines.

```erb
<%= render(Senren::InputComponent.new(name: "starts_at", type: "datetime-local")) %>
<%= render(Senren::InputComponent.new(name: "due_date", type: "date")) %>
```

---

## LabelComponent

### Required params

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `for_field` | String | **Yes** | — | ID of the associated form control |
| `text` | String | No | `nil` | Fallback label text (if block is empty) |
| `variant` | Symbol | No | `:default` | `:default` or `:required` (adds `*`) |

### Examples

Both patterns below are fully supported and produce identical output:

```erb
<%# Block syntax %>
<%= render(Senren::LabelComponent.new(for_field: "name", variant: :required)) { "Student name" } %>

<%# Text param syntax (useful when block content might be empty) %>
<%= render(Senren::LabelComponent.new(for_field: "name", text: "Student name", variant: :required)) %>
```

> **Note**: The `text:` param acts as a fallback. If both a block and `text:` are
> provided, the block content wins.

---

## NativeSelectComponent

Renders a native `<select>` element with Senren styling.

### Key behavior

- **Defaults to native browser arrow** (`native_arrow: true`). This preserves
  the platform's familiar select appearance (iOS wheel, Android dropdown, etc.).
- Pass `native_arrow: false` to use a custom SVG chevron overlay instead.

### Required params

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String/Symbol | **Yes** | — | Select `name` attribute |
| `options` | Array | **Yes** | — | `["a","b"]` or `[["val","Label"],...]` |
| `selected` | String | No | `nil` | Pre-selected value |
| `prompt` | String | No | `nil` | Blank option text (e.g., "Choose…") |
| `native_arrow` | Boolean | No | `true` | Use native browser arrow |
| `variant` | Symbol | No | `:default` | `:default` or `:error` |

### Examples

```erb
<%# Native arrow (default — recommended) %>
<%= render(Senren::NativeSelectComponent.new(
  name: "role",
  options: [["admin", "Admin"], ["member", "Member"]],
  prompt: "Choose role…"
)) %>

<%# Custom SVG arrow %>
<%= render(Senren::NativeSelectComponent.new(
  name: "role",
  options: [["admin", "Admin"], ["member", "Member"]],
  native_arrow: false
)) %>
```

---

## FormFieldComponent (pattern — not yet a shipped component)

A common pattern when building forms is wrapping label + control + error. Until a
dedicated `FormFieldComponent` ships, use this pattern:

```erb
<div class="space-y-1.5">
  <%= render(Senren::LabelComponent.new(for_field: "email", variant: :required)) { "Email" } %>
  <%= render(Senren::InputComponent.new(name: "email", type: "email", variant: @errors[:email] ? :error : :default)) %>
  <% if @errors[:email] %>
    <p class="text-sm text-[hsl(var(--senren-destructive))]"><%= @errors[:email] %></p>
  <% end %>
</div>
```

---

## Render syntax reminder

Always use **parentheses** around `render` when passing an inline content block:

```erb
<%# ✅ Correct: parens around render %>
<%= render(Senren::ButtonComponent.new(variant: :primary)) { "Save" } %>

<%# ✅ Correct: do/end block %>
<%= render Senren::ButtonComponent.new(variant: :primary) do %>
  Save
<% end %>

<%# ❌ Wrong: block attaches to .new, not render %>
<%= render Senren::ButtonComponent.new(variant: :primary) { "Save" } %>
```
