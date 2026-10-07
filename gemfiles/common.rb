# frozen_string_literal: true

# Development and test dependencies shared by the root Gemfile and every
# per-Rails gemfile in this directory. Declared once so a new dev dependency
# cannot be added to the default bundle and silently missing from the matrix.

group :development, :test do
  gem 'bundler-audit', require: false
  gem 'capybara'
  # ERB was the only layer with no linter, while being what 62 of the 64
  # components are actually written in.
  gem 'erb_lint', require: false
  # json 3.0 dropped the `quirks_mode:` option, and ActiveSupport::JSON's
  # JSONGemEncoder#stringify still passes it on Rails 7.1 and 8.0 (and on 7.2
  # before 7.2.4), so any tag option holding a hash or array raised
  # ArgumentError. Nothing in this gem needs json 3. RuboCop 1.91 no longer caps
  # json (`>= 2.3`, where 1.86 had `~> 2.3`), which is what let the per-Rails
  # lockfiles, resolved fresh on every run, pick it up. Lift this when the matrix
  # no longer includes a Rails that passes `quirks_mode:` (8.1 and 7.2.4 do not).
  gem 'json', '< 3'
  gem 'minitest'
  # Used only by component tests to parse rendered HTML. Not a runtime
  # dependency: the gem itself never parses HTML.
  gem 'nokogiri', '>= 1.19.3'
  # The asset pipeline the guard defends against. Needed to boot a throwaway app
  # with a real config.assets and prove the guard fires; without it there is no
  # config.assets at all and the test would pass vacuously.
  #
  # require: false is load-bearing. test/dummy calls Bundler.require, so an
  # auto-required propshaft installs its railtie into the dummy app and takes
  # over asset serving — which silently broke the lazy-loading system test, the
  # page loaded no controllers at all. The subprocess in
  # test/integration/asset_path_guard_boot_test.rb requires it explicitly.
  gem 'propshaft', require: false
  gem 'puma'
  gem 'rake'
  gem 'rubocop', require: false
  gem 'selenium-webdriver'
end
