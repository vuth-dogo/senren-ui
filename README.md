# Senren UI (`senren-ui`)

> 洗練 — refined, polished, sophisticated.

**[Live Docs & Component Reference → senren-ui.dev](https://www.senren-ui.dev)**

A Rails-native UI component library built on **ViewComponent**, **Hotwire
(Turbo + Stimulus)**, and **TailwindCSS**, with a centralized AI-agent
skill system and a source-copy install model inspired by shadcn/ui.

## What Senren is

- A Rails engine + generators that ship UI components into your host app.
- A registry of well-tested ViewComponents and Stimulus controllers.
- A centralized `.senren/skill.md` file so AI coding agents understand
  every installed component, its dependencies, and its anti-patterns.
- A multi-agent instruction sync for Codex, Claude, Copilot, and Cursor.

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

`senren:add` also works via `bundle exec rails senren:add ...`. The older
bracketed Rake task form, `bin/rails 'senren:add[button,card]'`, remains
supported for backward compatibility.

## Daily commands

```bash
bin/rails generate senren:install           # one-time setup
bin/rails generate senren:component picker --client  # custom component with Stimulus
bin/rails generate senren:component picker --no-client  # without Stimulus
bin/rails senren:add dialog --client        # install interactive official component
bin/rails senren:add button                 # install static official component
bundle exec rails senren:add form input     # equivalent alternate entry point
bin/rails senren:skill:sync                 # rebuild .senren/skill.md
bin/rails senren:agents:sync                # rebuild .senren/agent-rules + adapters
bin/rails senren:doctor                     # check installation health
```

## Keeping Stimulus JavaScript small

Senren copies only installed client controllers into your Rails app, but an
Importmap app can still download every controller on initial page load if it
keeps the default eager Stimulus loader and preload configuration. Once your
app has several interactive components, switch Stimulus to lazy loading:

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"

lazyLoadControllersFrom("controllers", application)
```

Disable import-map preloading for those on-demand controller modules:

```ruby
# config/importmap.rb
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
```

This keeps controllers mapped and usable while loading each module only when
its `data-controller` identifier appears in the page. Minification or source
maps are an application build/deployment decision; Senren deliberately ships
editable source controllers into the host app.

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

This repository ships as a gem source checkout with a git-ignored local
preview host:

```text
senren-ui/
  .local/
    preview/           # local Rails preview host, ignored by git
```

Use `bin/seed_preview` to create or refresh `.local/preview`. It
installs a small Senren component preview route, imports `senren.css`,
and loads Tailwind's browser runtime for local visual checks.

```bash
bin/seed_preview
cd .local/preview
bin/rails server
```

The full documentation/reference site lives outside this gem checkout in
`senren-ui-page`.

## AI Agent skill system

After install, your app contains:

- `.senren/skill.md` — centralized component guide for AI agents,
  grouped by Actions / Forms / Overlays / Navigation / Layout /
  Data Display / SaaS Blocks / Rich Content.
- `.senren/registry.yml` — mirror of the gem-side registry.
- `.senren/installed_components.yml` — ledger of installed components.
- `.senren/conventions.md` — Senren conventions for humans and agents.
- `.senren/agent-rules.md` — source of truth for generated agent rules.
- `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`,
  `.cursor/rules/senren.mdc` — marker-managed adapter files for each agent.

The skill file uses `<!-- senren:skill:start -->` / `:end` markers; only
the region between them is rewritten by the generator, so any notes you
add outside the markers are preserved.

Agent adapter files are also marker-managed, so Senren updates only its own
generated block and preserves your existing instructions outside that block.

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
bun install
bundle exec rake test            # gem tests
bin/system                       # headless browser system tests
bin/performance                  # local payload/performance budgets
bun run controllers:check        # lint + syntax check for templates/controllers/*.js
bun run controllers:lint:fix     # auto-fix lint issues for controllers
bundle exec rake test:system     # Stimulus/system tests
```

## Contributing

See `CONTRIBUTING.md`. Two rules to know up front:

1. Every meaningful change creates or updates a file in `history/`.
2. Architectural decisions are captured in `plans/` before code is
   written.

## Open source maintenance baseline

This repo ships with a GitHub baseline for safer public maintenance:

- CI on pull requests and `main` pushes for tests, RuboCop, and JS checks.
- CodeQL analysis for Ruby and JavaScript.
- Dependabot updates for Bundler, JS tooling, and GitHub Actions.
- PR and issue templates, `CODEOWNERS`, `CODE_OF_CONDUCT.md`, and
  `SECURITY.md`.

Repository controls such as branch protection, required checks, release
permissions, and auto-delete branch still need to be enabled in GitHub
repository settings.

## License

MIT — see `LICENSE`.
