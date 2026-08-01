# frozen_string_literal: true

require 'yaml'

# Loads test/fixtures/url_policy.yml for both the Ruby and the browser suites.
#
# The policy is implemented twice, in two languages, and has drifted once. This
# is the shared list they are both measured against, so the next divergence
# fails a test instead of shipping.
module UrlPolicyFixture
  PATH = File.expand_path('../fixtures/url_policy.yml', __dir__)

  module_function

  def data
    @data ||= YAML.safe_load_file(PATH).freeze
  end

  # Allowed values must be returned unchanged; rejected values must come back
  # as nil (Ruby callers pass `fallback: nil`; the client returns null).
  def vectors
    @vectors ||= (
      data.fetch('allowed').map { |v| v.merge('expect' => v.fetch('input')) } +
      data.fetch('rejected').map { |v| v.merge('expect' => nil) }
    ).freeze
  end

  def describe(vector)
    "#{vector.fetch('input').inspect} (#{vector.fetch('why').strip})"
  end
end
