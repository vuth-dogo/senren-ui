# frozen_string_literal: true

# Development and test dependencies shared by the root Gemfile and every
# per-Rails gemfile in this directory. Declared once so a new dev dependency
# cannot be added to the default bundle and silently missing from the matrix.

group :development, :test do
  gem 'bundler-audit', require: false
  gem 'capybara'
  gem 'minitest'
  # Used only by component tests to parse rendered HTML. Not a runtime
  # dependency: the gem itself never parses HTML.
  gem 'nokogiri', '>= 1.19.3'
  gem 'puma'
  gem 'rake'
  gem 'rubocop', require: false
  gem 'selenium-webdriver'
end
