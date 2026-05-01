# Plan 012 — Workspace and Todolist App

## Purpose

Define the workspace layout and the `apps/todolist` Rails app that
acts as the production-like acceptance test for Senren.

## Scope

- The `senren-workspace/` root layout.
- Local-path gem wiring.
- The Todo domain model.
- Required pages and which Senren components each page consumes.

## Decisions

1. The workspace root is the directory currently at
   `/home/vudogo/senren`. It contains `senren-rails/` and `apps/`.
2. `apps/todolist` is a Rails 7+ app generated with
   `rails new apps/todolist --css=tailwind --javascript=importmap`
   (or esbuild if importmap proves too constraining for Stimulus
   eager-load). The decision is locked at scaffold time and
   recorded in history.
3. The todolist app uses the gem via local path:

   ```ruby
   # apps/todolist/Gemfile
   gem "senren-ui", path: "../../senren-rails", require: "senren/rails"
   ```

4. Domain model:

   ```
   Todo
     title       :string   # required
     description :text
     status      :string   # pending|in_progress|completed|archived
     priority    :string   # low|medium|high|urgent
     due_on      :date
     completed_at:datetime
   ```

5. Routes: full RESTful `resources :todos`. `PATCH /todos/:id`
   supports Turbo Stream responses for status toggles.
6. Page-to-component mapping (from sections 14–15 of master prompt):
   - Index: AppShell, Sidebar, TopNav, PageHeader, Button, Card,
     Badge, Table/DataTable, DropdownMenu, Pagination, EmptyState,
     FilterBar, SearchInput.
   - New/Edit: Form, FormField, Label, Input, Textarea,
     NativeSelect/Select, DatePicker (if available), Button, Alert.
   - Show: Card, Badge, Button, Separator, Typography, ActivityFeed
     (if available).
   - Delete confirmation: AlertDialog, Button.
7. Seed data: 12 todos covering all status × priority combinations.
8. The todolist app has its own minimal test suite covering CRUD
   plus a system test that confirms a Senren-rendered button is
   present on the index page.

## Files to create

```
apps/todolist/Gemfile
apps/todolist/app/models/todo.rb
apps/todolist/app/controllers/todos_controller.rb
apps/todolist/app/views/todos/index.html.erb
apps/todolist/app/views/todos/show.html.erb
apps/todolist/app/views/todos/new.html.erb
apps/todolist/app/views/todos/edit.html.erb
apps/todolist/app/views/todos/_form.html.erb
apps/todolist/app/views/todos/_todo.html.erb
apps/todolist/db/migrate/<timestamp>_create_todos.rb
apps/todolist/db/seeds.rb
apps/todolist/config/routes.rb
apps/todolist/test/integration/senren_install_test.rb
apps/todolist/test/system/todo_index_test.rb
```

## Files to modify

- `apps/todolist/Gemfile` to add the local-path gem.
- `apps/todolist/config/application.rb` if any engine config needed.
- `apps/todolist/.senren/...` after running `senren:install`.

## Expected behavior

- From a clean checkout, the following sequence succeeds:

  ```bash
  cd senren-rails && bundle install
  cd ../apps/todolist
  bundle install
  bin/rails db:create db:migrate db:seed
  bin/rails generate senren:install
  bin/rails senren:add button card badge alert form input textarea \
    native_select table dropdown_menu dialog alert_dialog
  bin/rails server
  ```

- Visiting `/todos` shows a SaaS-style list rendered with Senren
  components, with working create/edit/delete flows.
- Deleting a todo opens an `AlertDialog` for confirmation.
- Status changes use Turbo Streams.

## Test strategy

- `bin/rails test` covers model + controller + integration.
- `bin/rails test:system` covers the index page render and the
  delete-confirmation flow.
- A history file records the integration result whenever the
  todolist app is exercised.

## Acceptance criteria

- [ ] Workspace contains `senren-rails/` and `apps/todolist/`.
- [ ] Gem loads via local path.
- [ ] Todo CRUD works.
- [ ] Index page uses at least eight Senren components.
- [ ] Form pages use Senren form components.
- [ ] Delete uses AlertDialog.
- [ ] Tests pass.
- [ ] History file documents the integration run.
