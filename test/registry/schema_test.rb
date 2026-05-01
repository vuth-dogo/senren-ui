# frozen_string_literal: true

require 'test_helper'

# Verifies the YAML registry obeys the schema documented in plans/003.
module Senren
  module Rails
    class RegistrySchemaTest < Minitest::Test
      REQUIRED = %w[category client can_have_client files depends_on pairs_with].freeze
      VALID_CATEGORIES = %w[actions forms overlays navigation layout data saas rich].freeze

      def raw
        @raw ||= YAML.safe_load_file(
          File.expand_path('../../registry/components.yml', __dir__)
        )['components']
      end

      def test_required_keys_present
        raw.each do |name, data|
          REQUIRED.each do |k|
            assert data.key?(k), "#{name} missing required key #{k}"
          end
        end
      end

      def test_categories_are_valid
        raw.each do |name, data|
          assert_includes VALID_CATEGORIES, data['category'],
                          "#{name} has invalid category #{data['category'].inspect}"
        end
      end

      def test_client_components_have_controller
        raw.each do |name, data|
          next unless data['client']

          assert_not_nil data['controller'],
                         "#{name} client=true but controller is missing"
          assert_match(/^senren--/, data['controller'],
                       "#{name} controller must start with 'senren--' (got #{data['controller']})")
        end
      end

      def test_files_are_well_formed
        raw.each do |name, data|
          assert data['files'].is_a?(Array), "#{name}: files must be an array"
          data['files'].each do |path|
            assert path.start_with?('app/'),
                   "#{name}: file paths must be host-relative starting with app/ (got #{path})"
          end
        end
      end
    end
  end
end
