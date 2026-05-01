# frozen_string_literal: true

require 'test_helper'

# Asserts that every component declared in the registry has its source files
# present under templates/, and that no token-violation patterns appear in
# component templates.
module Senren
  module Rails
    class TemplateFilesTest < Minitest::Test
      def setup
        @registry = Senren::Rails::Registry.load!(
          components_path: File.expand_path('../../registry/components.yml', __dir__),
          groups_path: File.expand_path('../../registry/groups.yml', __dir__),
          recipes_path: File.expand_path('../../registry/recipes.yml', __dir__)
        )
        @templates_root = File.expand_path('../../templates', __dir__)
      end

      def test_every_component_has_class_and_template
        @registry.find_each do |comp|
          base = File.join(@templates_root, 'components', comp.name)
          assert File.file?(File.join(base, "#{comp.name}_component.rb")),
                 "missing component class for #{comp.name}"
          assert File.file?(File.join(base, "#{comp.name}_component.html.erb")),
                 "missing component template for #{comp.name}"
        end
      end

      def test_every_client_component_has_controller_template
        @registry.all.select(&:client?).each do |comp|
          ctrl = File.join(@templates_root, 'controllers', "#{comp.name}_controller.js")
          assert File.file?(ctrl), "missing Stimulus controller for #{comp.name}: #{ctrl}"
        end
      end

      COLOR_FAMILIES = %w[
        gray slate zinc neutral stone red orange amber yellow lime green emerald
        teal cyan sky blue indigo violet purple fuchsia pink rose
      ].join('|')

      FORBIDDEN_COLOR_PATTERNS = [
        /\bbg-(?:#{COLOR_FAMILIES})-\d/,
        /\btext-(?:#{COLOR_FAMILIES})-\d/,
        /\bborder-(?:#{COLOR_FAMILIES})-\d/
      ].freeze

      def test_no_hardcoded_color_utilities_in_templates
        offenders = []
        Dir.glob(File.join(@templates_root, 'components', '**', '*.html.erb')).each do |path|
          content = File.read(path)
          FORBIDDEN_COLOR_PATTERNS.each do |re|
            if (m = content.match(re))
              offenders << "#{path}: #{m[0]}"
            end
          end
        end
        assert_empty offenders,
                     "hard-coded color utilities found; use semantic tokens instead:\n  - #{offenders.join("\n  - ")}"
      end
    end
  end
end
