# frozen_string_literal: true

require 'test_helper'
require 'senren/rails'
require 'senren/rails/component_copier'
require 'senren/rails/host_paths'
require 'senren/rails/registry'

module Senren
  module Rails
    class ComponentCopierTest < Minitest::Test
      def setup
        @root = Dir.mktmpdir
        @paths = HostPaths.new(@root)
        @stdout = StringIO.new
      end

      def teardown
        FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
      end

      def test_missing_template_aborts_before_installed_ledger_is_written
        copier = ComponentCopier.new(registry: ghost_registry, paths: @paths, stdout: @stdout)

        assert_raises(ComponentCopier::MissingTemplate) do
          copier.install(['ghost'])
        end

        refute @paths.installed_components.exist?
      end

      def test_install_migrates_existing_base_component_for_url_helpers
        @paths.ensure_dirs!
        File.write(@paths.base_component_path, <<~RUBY)
          module Senren
            class BaseComponent < ViewComponent::Base
            end
          end
        RUBY

        copier = ComponentCopier.new(registry: Registry.load!, paths: @paths, stdout: @stdout)
        copier.install(['link'])

        base_component = @paths.base_component_path.read

        assert_includes base_component, 'def safe_url'
        assert_includes base_component, 'def safe_media_url'
        assert_includes base_component, 'return url unless uri.scheme'
        assert_includes @stdout.string, 'url helpers'
        assert @paths.components_dir.join('link_component.html.erb').exist?
      end

      private

      def ghost_registry
        Registry.new(
          {
            'components' => {
              'ghost' => {
                'category' => 'actions',
                'client' => false,
                'can_have_client' => true,
                'files' => [
                  'app/components/senren/ghost_component.rb',
                  'app/components/senren/ghost_component.html.erb'
                ],
                'depends_on' => [],
                'pairs_with' => [],
                'variants' => [],
                'accessibility' => [],
                'ai' => { 'use_for' => [], 'avoid' => [] }
              }
            }
          },
          { 'groups' => [] },
          { 'recipes' => {} }
        )
      end
    end
  end
end
