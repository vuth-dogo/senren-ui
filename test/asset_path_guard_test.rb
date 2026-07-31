# frozen_string_literal: true

require 'test_helper'
require 'stringio'
require 'pathname'
require 'senren/rails/asset_path_guard'

module Senren
  module Rails
    # Guards against publishing component source.
    #
    # Verified against the real thing before this was written: with
    # app/components on the asset path, Propshaft 1.3.2 resolved 129 component
    # .rb/.erb files as assets, assets:precompile copied them into
    # public/assets, .manifest.json listed every one by logical name, and
    # fetching the digested URL returned the Ruby source with HTTP 200.
    class AssetPathGuardTest < Minitest::Test
      FakeApp = Struct.new(:root, :config)
      FakeConfig = Struct.new(:assets)
      FakeAssets = Struct.new(:paths)

      def setup
        @dir = Pathname.new(Dir.mktmpdir)
        @components = @dir.join('app/components/senren')
        @components.mkpath
        @components.join('button_component.rb').write("class ButtonComponent; end\n")
        @components.join('button_component.html.erb').write("<button></button>\n")
      end

      def teardown
        FileUtils.remove_entry(@dir) if @dir && Dir.exist?(@dir)
      end

      def app_with(paths)
        FakeApp.new(@dir, FakeConfig.new(FakeAssets.new(paths)))
      end

      def test_app_components_on_the_asset_path_is_reported
        app = app_with([@dir.join('app/components').to_s])

        refute_empty AssetPathGuard.offending_paths(app)
      end

      def test_an_ancestor_of_app_components_is_also_reported
        app = app_with([@dir.join('app').to_s])

        refute_empty AssetPathGuard.offending_paths(app),
                     'a parent directory publishes the same files'
      end

      # The point is not to ban sidecar assets, only to keep source out of them.
      def test_a_sibling_asset_directory_is_fine
        @dir.join('app/components/assets').mkpath
        app = app_with([@dir.join('app/components/assets').to_s])

        assert_empty AssetPathGuard.offending_paths(app)
      end

      def test_the_normal_asset_path_is_fine
        app = app_with([@dir.join('app/assets/stylesheets').to_s])

        assert_empty AssetPathGuard.offending_paths(app)
      end

      def test_an_app_with_no_component_source_is_fine
        FileUtils.rm_rf(@components)
        @components.mkpath
        app = app_with([@dir.join('app/components').to_s])

        assert_empty AssetPathGuard.offending_paths(app)
      end

      def test_development_warns_and_continues
        io = StringIO.new
        app = app_with([@dir.join('app/components').to_s])

        refute AssetPathGuard.check!(app, io: io)
        assert_includes io.string, 'app/components is on the asset load path'
        assert_includes io.string, 'Propshaft serves every file'
      end

      # A boot failure is recoverable; published source is not.
      def test_production_refuses_to_boot
        app = app_with([@dir.join('app/components').to_s])

        error = assert_raises(RuntimeError) do
          AssetPathGuard.check!(app, io: StringIO.new, production: true)
        end

        assert_includes error.message, 'app/components is on the asset load path'
      end

      def test_production_still_boots_a_clean_app
        app = app_with([@dir.join('app/assets').to_s])

        assert AssetPathGuard.check!(app, io: StringIO.new, production: true)
      end

      def test_a_clean_app_passes_silently
        io = StringIO.new
        app = app_with([@dir.join('app/assets').to_s])

        assert AssetPathGuard.check!(app, io: io)
        assert_empty io.string
      end

      # Without Rails loaded the environment lookup must not explode; the gem
      # is also required from rake tasks and generators.
      def test_environment_detection_survives_rails_being_absent
        refute AssetPathGuard.production_env?
      end
    end
  end
end
