# frozen_string_literal: true

require 'test_helper'
require 'rails/generators'
require 'rails/generators/test_case'
require 'generators/senren/install/install_generator'

module Senren
  module Generators
    # Asserts what the generator actually writes. Previously the only generator
    # coverage was an assertion about a Thor option's internal default, which
    # could not have caught a single defect in generated output.
    class InstallGeneratorTest < ::Rails::Generators::TestCase
      tests Senren::Generators::InstallGenerator
      destination File.expand_path('../../tmp/install_generator', __dir__)

      setup :prepare_destination

      def test_creates_the_expected_directory_layout
        run_generator

        assert_directory '.senren'
        assert_directory 'app/components/senren'
        assert_directory 'app/javascript/controllers/senren'
        assert_directory 'app/assets/stylesheets'
      end

      # Read out of the generator rather than typed here.
      #
      # A hand-kept list only covers what someone remembered to add to it, and
      # senren_themes.css shipped for a whole release without an entry -- the
      # generator wrote it, the test never looked, and a regression that stopped
      # writing it would have been silent. Deriving the list means adding a
      # `template` line to the generator extends this test automatically.
      GENERATOR_SOURCE = File.expand_path(
        '../../lib/generators/senren/install/install_generator.rb', __dir__
      )

      def declared_destinations
        File.read(GENERATOR_SOURCE)
            .scan(/^\s*(?:template|copy_file)\s+\S+?,\s*'([^']+)'/)
            .flatten
      end

      def test_the_generator_declares_the_files_this_test_checks
        assert_operator declared_destinations.size, :>=, 6,
                        'the destination scan matched almost nothing -- it has drifted from ' \
                        'the generator source and is no longer testing anything'
      end

      def test_writes_every_file_the_generator_declares
        run_generator

        declared_destinations.each { |path| assert_file path }
      end

      # Written by the writers rather than by a `template` line, so the scan
      # above cannot see them.
      def test_writes_the_generated_agent_files
        run_generator

        assert_file '.senren/skill.md'
        assert_file '.senren/agent-rules.md'
      end

      # Named, not derived, and that is the point.
      #
      # The derived test above only asks "is everything the generator declares
      # actually written". Delete the `template` line for the palettes and it
      # still passes, because the file it no longer writes is also no longer
      # declared -- the list moves with the bug. These two are load-bearing
      # enough to be spelled out: senren.css is the token set every component
      # renders against, and senren_themes.css is the palette feature. An
      # install missing either produces an app that boots and renders unstyled.
      def test_the_install_is_not_complete_without_the_stylesheets
        run_generator

        assert_file 'app/assets/stylesheets/senren.css' do |content|
          assert_includes content, ':root', 'the token set must declare :root'
          assert_includes content, '--senren-primary'
        end

        assert_file 'app/assets/stylesheets/senren_themes.css' do |content|
          assert_includes content, '[data-senren-theme=', 'the palette presets must ship with the install'
          assert_includes content, '--senren-primary',
                          'a palette that does not redeclare the tokens overrides nothing'
        end
      end

      # senren_themes.css only takes effect if it is loaded after senren.css --
      # the palettes and :root have equal specificity, so source order decides.
      # An install that writes both but documents no order produces a themed app
      # that renders in the base palette.
      def test_the_theme_load_order_is_stated_where_someone_will_read_it
        run_generator

        assert_file '.senren/conventions.md' do |content|
          assert_includes content, 'senren_themes.css',
                          'the conventions file the agents read must mention the palette stylesheet'
        end
      end

      # The template escapes its ERB examples as `<%%=` so Thor emits a literal
      # `<%=`. A copier that does not evaluate ERB would leave `<%%=` in place,
      # producing a conventions file whose code samples cannot be pasted.
      def test_conventions_file_renders_escaped_erb_examples
        run_generator

        assert_file '.senren/conventions.md' do |content|
          assert_includes content, '<%= render(Senren::ButtonComponent',
                          'escaped ERB must render to a usable example'
        end
      end

      # Across everything written, not just the conventions file.
      #
      # senren_themes.css escapes two stylesheet_link_tag examples in its header
      # comment and was never checked. A copy of it reached a real application
      # with the raw `<%%=` intact, because the only assertion of this kind
      # named one file -- so the property held exactly where someone had thought
      # to look, which is the same as not holding.
      def test_no_generated_file_leaks_a_raw_erb_escape
        run_generator

        leaked = Dir.glob(File.join(destination_root, '**', '*'), File::FNM_DOTMATCH)
                    .select { |path| File.file?(path) }
                    .select { |path| File.read(path).include?('<%%') }
                    .map { |path| path.sub("#{destination_root}/", '') }

        assert_empty leaked,
                     'these shipped an unrendered ERB escape, so what the user reads is ' \
                     "`<%%=` where the example should say `<%=`: #{leaked.join(', ')}"
      end

      def test_base_component_ships_the_hardened_url_helpers
        run_generator

        assert_file 'app/components/senren/base_component.rb' do |content|
          assert_includes content, 'def safe_url'
          assert_includes content, 'def safe_media_url'
          assert_includes content, "url.include?('\\\\')",
                          'the copied helper must reject backslash bypasses'
          assert_includes content, '[[:cntrl:]]',
                          'the copied helper must reject control characters'
        end
      end

      def test_registry_mirror_matches_the_gem_registry
        run_generator

        mirrored = YAML.safe_load_file(File.join(destination_root, '.senren/registry.yml'))
        source = YAML.safe_load_file(Senren::Rails.registry_path)

        assert_equal source, mirrored
      end

      def test_generated_ledger_starts_empty_and_is_valid_yaml
        run_generator

        ledger = YAML.safe_load_file(File.join(destination_root, '.senren/installed_components.yml'))

        assert_kind_of Hash, ledger
        assert_empty Array(ledger['installed'])
      end

      # Re-running an installer is normal after a gem upgrade. It must not
      # duplicate marker blocks in the agent-facing files.
      def test_rerunning_the_generator_does_not_duplicate_marker_blocks
        run_generator
        first = read_generated('.senren/skill.md')

        run_generator ['--force']
        second = read_generated('.senren/skill.md')

        assert_equal 1, second.scan('senren:skill:start').size, 'exactly one start marker'
        assert_equal 1, second.scan('senren:skill:end').size, 'exactly one end marker'
        assert_equal first, second, 'a second run must converge, not grow the file'
      end

      def test_agent_adapter_files_are_marker_managed
        run_generator

        %w[AGENTS.md CLAUDE.md .github/copilot-instructions.md .cursor/rules/senren.mdc].each do |path|
          assert_file path do |content|
            assert_includes content, 'senren:agent', "#{path} should carry the managed marker"
          end
        end
      end

      # The lazy-loading contract, asserted against the files Rails actually
      # generates. It used to be a README paragraph plus a bin/performance check
      # that grepped that README, so every host shipped every controller on
      # every page while CI reported PASS.
      def test_switches_the_default_eager_loader_to_lazy
        seed_default_importmap_app
        run_generator

        assert_file 'app/javascript/controllers/index.js' do |content|
          assert_includes content, 'lazyLoadControllersFrom("controllers", application)'
          refute_includes content, 'eagerLoadControllersFrom'
        end
      end

      def test_disables_modulepreload_for_controllers
        seed_default_importmap_app
        run_generator

        assert_file 'config/importmap.rb' do |content|
          assert_match(%r{pin_all_from "app/javascript/controllers".*preload: false}, content)
        end
      end

      # Running install again after a gem upgrade must not double-edit.
      def test_stimulus_wiring_is_idempotent
        seed_default_importmap_app
        run_generator
        first_index = read_generated('app/javascript/controllers/index.js')
        first_map = read_generated('config/importmap.rb')

        run_generator ['--force']

        assert_equal first_index, read_generated('app/javascript/controllers/index.js')
        assert_equal first_map, read_generated('config/importmap.rb')
        assert_equal 1, first_map.scan('preload: false').size
      end

      # An app that already chose its own loading strategy is left alone.
      def test_a_custom_loader_is_not_rewritten
        seed_default_importmap_app
        write_host_file 'app/javascript/controllers/index.js', "// hand rolled\nregisterEverything()\n"

        run_generator

        assert_file 'app/javascript/controllers/index.js' do |content|
          assert_includes content, 'registerEverything()'
          refute_includes content, 'lazyLoadControllersFrom'
        end
      end

      def test_an_app_without_importmap_is_reported_not_crashed
        run_generator

        assert_file 'app/components/senren/base_component.rb'
      end

      private

      # Mirrors what `rails new` produces for an importmap application.
      def seed_default_importmap_app
        write_host_file 'config/importmap.rb', <<~RUBY
          pin "application"
          pin_all_from "app/javascript/controllers", under: "controllers"
        RUBY

        write_host_file 'app/javascript/controllers/index.js', <<~JS
          import { application } from "controllers/application"
          import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
          eagerLoadControllersFrom("controllers", application)
        JS
      end

      def write_host_file(relative, content)
        path = File.join(destination_root, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end

      def read_generated(relative)
        File.read(File.join(destination_root, relative))
      end
    end
  end
end
