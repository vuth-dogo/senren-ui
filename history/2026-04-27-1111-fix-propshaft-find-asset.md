# Fix: Propshaft `find_asset` NoMethodError in Todolist Layout

## Time

2026-04-27 11:11 UTC

## Symptom

Visiting `Todos#index` raised:

```text
NoMethodError: undefined method 'find_asset' for an instance of Propshaft::Assembly
```

The exception came from `apps/todolist/app/views/layouts/application.html.erb` line 22:

```erb
Rails.application.assets&.find_asset("senren.css")
```

## Cause

The app uses Propshaft, and `Propshaft::Assembly` does not expose the Sprockets-style `find_asset` API. The check was unnecessary because Senren installation owns and installs `app/assets/stylesheets/senren.css`.

## Fix

Changed the layout to always include the installed Senren stylesheet:

```erb
<%= stylesheet_link_tag "senren", "data-turbo-track": "reload" %>
```

## Verification

```bash
cd /home/vudogo/senren/apps/todolist
source ~/.bashrc
bin/rails test
bin/rails runner 'app = ActionDispatch::Integration::Session.new(Rails.application); app.host!("localhost"); app.get "/"; puts app.response.status; puts app.response.body.include?("Todos")'
```

Results:

```text
12 runs, 54 assertions, 0 failures, 0 errors, 0 skips
200
true
```
