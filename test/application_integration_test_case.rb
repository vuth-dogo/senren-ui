# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative 'dummy/config/environment'
require 'rails/test_help'
# Required explicitly: the dummy app loads the component classes, but the
# Registry constant only arrives via the preview helper, which is autoloaded on
# first request. A test that never makes one would not have it.
require 'senren/rails'

# Server-side rendering against the dummy app, without a browser.
#
# This exists because `rake test` — and therefore `bin/matrix` — excludes
# test/system, so browser tests only ever ran on one Rails version. Rendering is
# the part of a ViewComponent library that actually depends on the Rails
# version, so it belongs in a suite the matrix executes.
class ApplicationIntegrationTestCase < ActionDispatch::IntegrationTest
end
