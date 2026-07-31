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

      # 'ghost' is can_have_client but lists no controller file, so --client
      # cannot install anything. Silently recording client: true in the ledger
      # would misinform both developers and the AI agents that read it.
      def test_client_override_without_a_controller_is_rejected
        copier = ComponentCopier.new(registry: ghost_registry, paths: @paths, stdout: @stdout)

        error = assert_raises(ArgumentError) do
          copier.install(['ghost'], client_override: true)
        end

        assert_includes error.message, 'ghost'
        assert_includes error.message, '--client'
        refute @paths.installed_components.exist?, 'no ledger entry may be written for a rejected install'
      end

      def test_client_override_only_validates_explicitly_requested_components
        copier = ComponentCopier.new(registry: Registry.load!, paths: @paths, stdout: @stdout)

        # dialog ships a controller; whatever it pulls in as a dependency must
        # not fail the install just because it has none.
        copier.install(['dialog'], client_override: true)

        entry = YAML.safe_load_file(@paths.installed_components)['installed'].find { |e| e['name'] == 'dialog' }

        assert entry['client'], 'dialog installs a controller, so the ledger should record client: true'
        assert @paths.stimulus_dir.join('dialog_controller.js').exist?
      end

      def test_ledger_never_records_client_for_a_component_without_a_controller
        copier = ComponentCopier.new(registry: Registry.load!, paths: @paths, stdout: @stdout)
        copier.install(['button'])

        entry = YAML.safe_load_file(@paths.installed_components)['installed'].find { |e| e['name'] == 'button' }

        refute entry['client'], 'button has no controller file, so the ledger must not claim client behavior'
      end

      # Regression: the base-component migration appends with File.open(_, 'a')
      # rather than going through copy_file, so it bypassed both the symlink
      # refusal and the containment check. Path expansion does not resolve
      # symlinks, so the write landed on the link's target — outside the app
      # root that containment exists to enforce.
      def test_url_helper_migration_refuses_to_append_through_a_symlink
        outside = Pathname.new(Dir.mktmpdir)
        victim = outside.join('victim.rb')
        victim.write("# outside the app root\n")

        @paths.ensure_dirs!
        @paths.base_component_path.parent.mkpath
        File.symlink(victim.to_s, @paths.base_component_path.to_s)

        copier = ComponentCopier.new(registry: Registry.load!, paths: @paths, stdout: @stdout)
        copier.send(:ensure_base_component_url_helpers!)

        assert_equal "# outside the app root\n", victim.read,
                     'nothing may be written through the symlink'
        assert_includes @stdout.string, 'symlink'
      ensure
        FileUtils.remove_entry(outside) if outside && Dir.exist?(outside)
      end

      def test_copy_refuses_to_write_outside_the_app_root
        copier = ComponentCopier.new(registry: Registry.load!, paths: @paths, stdout: @stdout)
        escape = Pathname.new(@root).join('..', 'escaped_component.rb')

        error = assert_raises(ArgumentError) do
          copier.send(:assert_inside_host_root!, escape, 'escape::test')
        end

        assert_includes error.message, 'Refusing to write outside the app root'
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
