# Senren UI (`senren-ui`)

> 洗練 — refined, polished, sophisticated.

A Rails-native UI component library built on **ViewComponent**, **Hotwire
(Turbo + Stimulus)**, and **TailwindCSS**, with a centralized AI-agent
skill system and a source-copy install model inspired by shadcn/ui.

## What Senren is

- A Rails engine + generators that ship UI components into your host app.
- A registry of well-tested ViewComponents and Stimulus controllers.
- A centralized `.senren/skill.md` file so AI coding agents understand
  every installed component, its dependencies, and its anti-patterns.
- An `llms.txt` / `llms-full.txt` generator so AI agents can discover
  Senren without scraping your codebase.

## What Senren is not

- Not React, Vue, Alpine, or any external state framework.
- Not a CSS-only kit — components ship Ruby + ERB + (optional) Stimulus.
- Not an opaque dependency — installed components live in your app
  under `app/components/senren/` and you own them.

## Installation

Add to your Rails app's `Gemfile`:

```ruby
gem "senren-ui", path: "../../senren-rails", require: "senren/rails"   # local path during dev
# or once published:
# gem "senren-ui", require: "senren/rails"
```

Then:

```bash
bundle install
bin/rails generate senren:install
bin/rails senren:add button card badge alert form input \
  textarea native_select table dropdown_menu dialog alert_dialog
```

## Daily commands

```bash
bin/rails generate senren:install           # one-time setup
bin/rails generate senren:component picker --client  # custom component with Stimulus
bin/rails generate senren:component picker --no-client  # without Stimulus
bin/rails senren:add dialog --client        # install interactive official component
bin/rails senren:add button                 # install static official component
bin/rails senren:skill:sync                 # rebuild .senren/skill.md
bin/rails senren:llms:generate              # rebuild public/llms*.txt
bin/rails senren:doctor                     # check installation health
```

## Using a component

```erb
<%= render Senren::ButtonComponent.new(variant: :primary) do %>
  Save changes
<% end %>

<%= render Senren::CardComponent.new do |card| %>
  <% card.with_header { "Account settings" } %>
  <% card.with_body   { "Manage your account details." } %>
  <% card.with_footer do %>
    <%= render(Senren::ButtonComponent.new(variant: :primary)) { "Save" } %>
  <% end %>
<% end %>
```

## Workspace layout

This repository ships as a workspace with a real Rails dogfooding app:

```text
senren-workspace/
  senren-rails/        # the local gem source directory
  apps/
    todolist/          # real Rails app that uses senren-ui via local path
```

`apps/todolist` is the production-like acceptance test for Senren — a
small SaaS-style Todo manager built entirely from Senren components.

## AI Agent skill system

After install, your app contains:

- `.senren/skill.md` — centralized component guide for AI agents,
  grouped by Actions / Forms / Overlays / Navigation / Layout /
  Data Display / SaaS Blocks / Rich Content.
- `.senren/registry.yml` — mirror of the gem-side registry.
- `.senren/installed_components.yml` — ledger of installed components.
- `.senren/conventions.md` — Senren conventions for humans and agents.
- `public/llms.txt`, `public/llms-full.txt` — discoverable AI summary.

The skill file uses `<!-- senren:skill:start -->` / `:end` markers; only
the region between them is rewritten by the generator, so any notes you
add outside the markers are preserved.

## Component list

See `registry/components.yml` for the canonical list. v0.1 ships:

- **Phase 1 — Foundation** (full): Button, Link, Badge, Typography,
  Separator, Skeleton, Avatar, Alert, Card, AspectRatio.
- **Phase 2 — Forms** (full): Form, Input, Textarea, Checkbox,
  CheckboxGroup, RadioButton, NativeSelect, Select, Switch, MaskedInput.
- **Phase 3 — Overlays** (full): Dialog, AlertDialog, DropdownMenu,
  Popover, Tooltip, HoverCard, Sheet, ContextMenu.
- **Phases 4–6** (scaffolded stubs): Navigation/Layout, Data/Advanced,
  SaaS Blocks. Each is registered, has a class, and renders a clearly
  marked placeholder until promoted to full implementation.

## Development

```bash
bundle install
bundle exec rake test            # gem tests
bundle exec rake test:system     # Stimulus/system tests
```

## Contributing

See `CONTRIBUTING.md`. Two rules to know up front:

1. Every meaningful change creates or updates a file in `history/`.
2. Architectural decisions are captured in `plans/` before code is
   written.

## License

MIT — see `LICENSE`.
