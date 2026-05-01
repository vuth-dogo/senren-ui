# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require 'yaml'

# Avoid loading the Rails engine in pure-Ruby unit tests by stubbing the
# constant check used by lib/senren/rails.rb.
require 'senren/rails/version'
require 'senren/rails/registry'

module Minitest
  module Assertions
    def assert_not(test, msg = nil)
      assert !test, msg
    end

    def assert_not_empty(collection, msg = nil)
      refute_empty collection, msg
    end

    def assert_not_nil(object, msg = nil)
      refute_nil object, msg
    end
  end
end
