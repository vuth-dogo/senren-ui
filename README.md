# Senren UI (`senren-ui`)

> 洗練 *(senren)* — Japanese for "refinement".

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

## Scope

Senren renders on the server. Components are ViewComponent classes with ERB
templates, interactivity is Stimulus, and server state is Turbo's job. It is
not a client-side rendering layer: if your app is built around React, Vue, or
another client framework, a component library from that ecosystem will fit it
better than this one.

Two other things worth knowing up front:

- Components ship as Ruby + ERB + optional Stimulus, not as a CSS-only kit.
- They are copied into your app under `app/components/senren/`, so they are
  yours to read and edit rather than an opaque dependency.

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

## Palettes

The install writes two stylesheets. `senren.css` is the token set every
component renders against; `senren_themes.css` is optional and adds five
alternate palettes.

```erb
<%= stylesheet_link_tag "senren" %>
<%= stylesheet_link_tag "senren_themes" %>   <%# after senren.css %>
```

```erb
<html data-senren-theme="rose">
```

`rose`, `slate`, `indigo`, `emerald`, `amber` — or omit the attribute for the
default, Spring Garden. Order matters: `:root` and `[data-senren-theme="rose"]`
have equal specificity, so the file that loads last wins. Reversed, nothing
errors and the page quietly renders in the default palette.

A theme is a re-declaration of the same tokens and nothing else. No component
reads the attribute, so a sixth palette is a copied CSS block — no component
change, no build step, no configuration. Switch at runtime with
`document.documentElement.dataset.senrenTheme = "slate"`.

Details and the token table: [docs/visual_style.md](docs/visual_style.md).

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

### What reloads while you work

Components copied into your app are ordinary Rails code, so editing a
`*_component.rb` or `*.html.erb` takes effect on the next request with no
restart. The exception is Stimulus: a controller under
`app/javascript/controllers/senren/` is a module the browser has already
fetched, so editing it needs a page reload — the server does not need
restarting. `docs/hot_reload.md` has the details, including Turbo morphing.

## Keeping Stimulus JavaScript small

`bin/rails generate senren:install` wires on-demand controller loading for
you. It switches `app/javascript/controllers/index.js` from Rails' default
`eagerLoadControllersFrom` to `lazyLoadControllersFrom`, and adds
`preload: false` to the controllers pin in `config/importmap.rb`.

Without it, an Importmap app downloads **every** controller on **every** page.
`pin_all_from "app/javascript/controllers"` is recursive, so it covers
`app/javascript/controllers/senren` too — a static marketing page paid for the
rich text editor. With it, a module is fetched the first time its
`data-controller` identifier appears, including markup Turbo inserts later.

Two things worth knowing:

- It changes loading for **your** controllers as well, because it uses the
  official `stimulus-loading` helper rather than a Senren-specific loader.
  Lazy loading is the better default for almost every app, but it is your
  call — the generator only edits the file while it still carries the
  untouched Rails default, and reports what it did.
- If you have already customised `index.js`, or you bundle with esbuild or
  Vite instead of Importmap, the generator leaves it alone and says so.

This used to be a paragraph asking you to do it by hand, and a CI check that
passed as long as the paragraph existed. It is now installed and asserted in
`test/generators/install_generator_test.rb` against the files `rails new`
actually produces.

## Component source in production

Senren copies editable ViewComponent, ERB and Stimulus source into your app.
That is the point of the design, and it means minification and source maps are
your app's decision, not the gem's — Senren ships readable source and gets out
of the way.

Readable in your repo is not the same as readable over HTTP, and there is one
configuration that turns the first into the second:

```ruby
# config/initializers/assets.rb — do NOT do this
Rails.application.config.assets.paths << Rails.root.join("app/components")
```

That line appears in guidance about ViewComponent sidecar assets, and under
Propshaft it publishes the whole directory. Reproduced against Propshaft 1.3.2:
every `.rb` and `.html.erb` under `app/components` was resolved as an asset,
`RAILS_ENV=production rails assets:precompile` copied them into `public/assets`,
`public/assets/.manifest.json` listed each one next to its digested filename —
so the digest is not a secret — and requesting the digested URL returned the
Ruby source with `HTTP 200`, served by the web server without Rails involved.

Senren refuses to let this ship. A boot check runs after your initializers:

- **production** — raises, so the app does not boot and `assets:precompile`
  fails. A failed deploy is recoverable; published source is not.
- **anywhere else** — prints a warning and carries on, because development is a
  different risk calculation.

It only objects when component source actually sits under an asset path, so
sidecar assets remain available — put them in their own directory:

```ruby
Rails.application.config.assets.paths << Rails.root.join("app/components/assets")
```

The default configuration is unaffected: with no such line, every component
path returns `404`. The gem itself adds no production request-path code, and
this check is the sole exception.

See `test/asset_path_guard_test.rb` and
`test/integration/asset_path_guard_boot_test.rb`, which boot a real Rails app
with a real Propshaft and assert that precompile cannot publish source.

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

See `registry/components.yml` for the canonical list. Currently shipping:

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
bin/lint-fix                     # auto-fix RuboCop, ERB lint, and controller JS
```

## Contributing

See `CONTRIBUTING.md`. Two rules to know up front:

1. Every meaningful change creates or updates a file in `history/`.
2. Architectural decisions are captured in `plans/` before code is
   written.

## Project health

Every push runs the test suite, RuboCop, and the JavaScript checks against
Ruby 3.2–3.4 × Rails 7.1–8.1. CodeQL scans Ruby and JavaScript, and Dependabot
tracks Bundler, JS tooling, and Actions.

Security reports go to `SECURITY.md`.

## Acknowledgements

Senren builds on ideas from prior art. No source code from either project is
included here — the influence is on architecture and developer experience, and
both are credited because ideas have authors even when licences do not require
the notice.

- [shadcn/ui](https://github.com/shadcn-ui/ui) (MIT) — the source-copy install
  model: components are copied into your app so you own and can edit them,
  rather than being rendered from inside a dependency.
- [jetrockets/jet_ui](https://github.com/jetrockets/jet_ui) (MIT, © 2026
  JetRockets) — a Rails/ViewComponent UI library whose maintainers write openly
  about the trade-offs they worked through. That writing informed
  `plans/022_jet_ui_lessons.md`: how Tailwind's content scanning interacts with
  components shipped from inside a gem, and the case for testing every Ruby and
  Rails version a gem claims to support. Both points made this library better.

Both are MIT licensed, which permits use, modification, and study. The MIT
notice requirement attaches to copies of the software; since Senren copies no
code from either, this section is attribution rather than a licence obligation.

## License

MIT — see `LICENSE`.
