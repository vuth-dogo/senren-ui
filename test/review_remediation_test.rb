# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'yaml'
require 'senren/rails'

module Senren
  module Rails
    # Regressions for defects found in the 2026-08-01 architecture review. Each
    # was reproduced by execution before being fixed; each assertion here was
    # watched failing against the unfixed code.
    class ReviewRemediationTest < Minitest::Test
      def setup
        @root = Pathname.new(Dir.mktmpdir('senren-review'))
      end

      def teardown
        FileUtils.remove_entry(@root) if @root&.exist?
      end

      # `gem "senren-ui"` with no require: option. Bundler tries "senren-ui",
      # then "senren/ui", and swallows the second LoadError -- so the app booted
      # with no engine, no rake tasks, and no AssetPathGuard, while the
      # generator kept working because it requires senren/rails itself. The
      # install looked healthy and the production source-disclosure guard was
      # simply absent.
      def test_the_gem_name_is_a_working_require_path
        assert_path_exists File.expand_path('../lib/senren-ui.rb', __dir__),
                           'the default Bundler require target must exist'
      end

      # spec.files globs the filesystem, so an untracked file would still be
      # packaged from a dirty checkout and vanish from a clean one.
      def test_the_default_require_target_is_tracked_by_git
        files = `git -C #{File.expand_path('..', __dir__)} ls-files lib/senren-ui.rb`.strip

        refute_empty files, 'lib/senren-ui.rb must be committed, not merely present'
      end

      # --client / --no-client describes the requested components. Applying it
      # to the whole dependency closure suppressed dropdown_menu's controller
      # when installing context_menu, and dropdown_menu's markup emits
      # data-controller unconditionally -- so the menu silently never opened.
      def test_no_client_does_not_strip_controllers_from_dependencies
        install(['context_menu'], client_override: false)

        assert_path_exists @root.join('app/javascript/controllers/senren/dropdown_menu_controller.js'),
                           'a dependency keeps the controller its own markup requires'
        refute_path_exists @root.join('app/javascript/controllers/senren/context_menu_controller.js'),
                           'the requested component still honours --no-client'
      end

      def test_the_ledger_records_dependencies_as_installed
        install(['context_menu'], client_override: false)

        assert_equal true, ledger_entry('dropdown_menu')['client']
        assert_equal false, ledger_entry('context_menu')['client']
      end

      # The ledger's client flag had no reader, so skill.md described the
      # registry default and named controller files that were never copied.
      def test_the_skill_file_does_not_promise_uninstalled_controllers
        install(['context_menu'], client_override: false)
        SkillWriter.new(paths: paths).sync!
        skill = @root.join('.senren/skill.md').read

        refute_includes skill, 'controllers/senren/context_menu_controller.js',
                        'skill.md must not name a controller that was not installed'
        assert_includes skill, 'controllers/senren/dropdown_menu_controller.js',
                        'the dependency controller was installed and should be described'
      end

      # The mirror was written once and never refreshed, while the generated
      # agent rules advertise it as authoritative.
      def test_installing_refreshes_the_registry_mirror
        paths.senren_dir.mkpath
        paths.registry_mirror.write("installed: []\n")
        install(['button'])

        assert_equal YAML.safe_load_file(Senren::Rails.registry_path),
                     YAML.safe_load_file(paths.registry_mirror)
      end

      # NAME_PATTERN accepts consecutive underscores; "foo__bar".split("_")
      # yields an empty segment and w[0] was nil. It raised after files were
      # copied, leaving a half-completed install.
      def test_humanize_survives_consecutive_underscores
        writer = SkillWriter.new(paths: paths)

        assert_equal 'FooBar', writer.send(:humanize, 'foo__bar')
      end

      private

      def paths
        @paths ||= HostPaths.new(@root)
      end

      def install(names, client_override: nil)
        ComponentInstaller.new(paths: paths, stdout: StringIO.new)
                          .install(names: names, client_override: client_override)
      end

      def ledger_entry(name)
        YAML.safe_load_file(paths.installed_components)['installed'].find { |e| e['name'] == name }
      end
    end
  end
end
