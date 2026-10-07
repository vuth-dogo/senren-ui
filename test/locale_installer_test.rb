# frozen_string_literal: true

require 'test_helper'
require 'senren/rails'
require 'senren/rails/host_paths'
require 'senren/rails/locale_installer'

module Senren
  module Rails
    # The shipped translations are source that gets copied, like a component, and
    # they carry the same obligations: land inside the app root, and never undo
    # what the host did to its own copy.
    class LocaleInstallerTest < Minitest::Test
      SHIPPED = File.expand_path('../templates/locales', __dir__)

      def setup
        @root = Dir.mktmpdir
        @paths = HostPaths.new(@root)
        @stdout = StringIO.new
        @installer = LocaleInstaller.new(paths: @paths, stdout: @stdout)
      end

      def teardown
        FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
      end

      def test_the_gem_ships_english_and_vietnamese
        assert_equal %w[en vi], LocaleInstaller.available
      end

      def test_host_paths_name_one_file_per_locale
        assert_equal File.join(File.realpath(@root), 'config/locales/senren.vi.yml'),
                     @paths.locale_file('vi').to_s.sub(@root, File.realpath(@root))
      end

      def test_english_is_installed_when_nothing_is_asked_for
        written = @installer.install

        assert_equal %w[en], written
        assert_equal File.read(File.join(SHIPPED, 'senren.en.yml')), @paths.locale_file('en').read
        refute @paths.locale_file('vi').exist?, 'a translation is opt-in: it adds a locale to I18n.available_locales'
      end

      def test_a_named_translation_is_installed_beside_english
        written = @installer.install(locales: %w[en vi])

        assert_equal %w[en vi], written
        assert_equal File.read(File.join(SHIPPED, 'senren.vi.yml')), @paths.locale_file('vi').read
      end

      def test_the_config_locales_directory_is_created_when_the_app_has_none
        refute @paths.locales_dir.exist?

        @installer.install

        assert @paths.locales_dir.directory?
      end

      # The file is the host's translation. Running the installer again after a
      # gem upgrade must not undo it.
      def test_an_existing_file_is_kept
        @installer.install(locales: %w[vi])
        @paths.locale_file('vi').write("vi:\n  senren:\n    pagination:\n      next: \"Tiếp\"\n")

        written = @installer.install(locales: %w[vi])

        assert_empty written
        assert_includes @paths.locale_file('vi').read, 'Tiếp'
        assert_includes @stdout.string, 'skip'
        assert_includes @stdout.string, '--force'
      end

      def test_force_replaces_an_existing_file
        @installer.install(locales: %w[vi])
        @paths.locale_file('vi').write("vi:\n  senren:\n    pagination:\n      next: \"Tiếp\"\n")

        written = @installer.install(locales: %w[vi], force: true)

        assert_equal %w[vi], written
        assert_equal File.read(File.join(SHIPPED, 'senren.vi.yml')), @paths.locale_file('vi').read
      end

      def test_an_unshipped_locale_is_refused_with_the_way_to_add_one
        error = assert_raises(ArgumentError) { @installer.install(locales: %w[fr]) }

        assert_includes error.message, 'fr'
        assert_includes error.message, 'en, vi'
        assert_includes error.message, 'senren.en.yml', 'the message must say how to add the language by hand'
      end

      # Every name is checked before any file is written.
      def test_a_bad_name_writes_nothing_even_after_a_good_one
        assert_raises(ArgumentError) { @installer.install(locales: %w[vi fr]) }

        refute @paths.locale_file('vi').exist?
        refute @paths.locales_dir.exist?
      end

      def test_a_name_that_is_not_a_locale_is_refused
        ['../escape', 'vi/../../x', 'VI yml', ''].each do |name|
          next if name.empty?

          assert_raises(ArgumentError, "#{name.inspect} must be refused") { @installer.install(locales: [name]) }
        end
      end

      # A checkout can ship config/locales as a link to somewhere else. Writing
      # through it would put a file outside the project.
      def test_it_does_not_write_through_a_link_that_leaves_the_app_root
        outside = Dir.mktmpdir
        FileUtils.mkdir_p(File.join(@root, 'config'))
        File.symlink(outside, File.join(@root, 'config/locales'))

        written = @installer.install

        assert_empty written
        assert_includes @stdout.string, 'skip'
        assert_includes @stdout.string, 'outside the app root'
        assert_empty Dir.children(outside), 'nothing may be written outside the root'
      ensure
        FileUtils.remove_entry(outside) if outside && Dir.exist?(outside)
      end
    end
  end
end
