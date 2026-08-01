# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'senren/rails'
require 'senren/rails/safe_write'
require 'senren/rails/host_paths'
require 'senren/rails/component_copier'

module Senren
  module Rails
    # Containment against a repository you clone and run senren:install in.
    #
    # The original defences were lexical: assert_inside_host_root! used
    # Pathname#expand_path, which normalises `..` but does NOT resolve symlinks,
    # and refuse_symlink? tested only the leaf. A checkout shipping
    # app/components/senren as a link to somewhere outside the project defeated
    # both and every copied file landed outside the app root -- verified before
    # this file was written.
    class SafeWriteTest < Minitest::Test
      def setup
        @sandbox = Pathname.new(Dir.mktmpdir('senren-safe-write'))
        @root = @sandbox.join('app_root')
        @outside = @sandbox.join('OUTSIDE')
        @root.mkpath
        @outside.mkpath
      end

      def teardown
        FileUtils.remove_entry(@sandbox) if @sandbox&.exist?
      end

      def test_an_ordinary_path_is_inside
        assert SafeWrite.inside?(@root.join('app/components/senren/x.rb'), @root)
      end

      def test_a_traversal_is_outside
        refute SafeWrite.inside?(@root.join('../OUTSIDE/x.rb'), @root)
      end

      # The one expand_path could not see.
      def test_a_symlinked_ancestor_is_outside
        @root.join('app').mkpath
        File.symlink(@outside.to_s, @root.join('app/components').to_s)

        refute SafeWrite.inside?(@root.join('app/components/senren/x.rb'), @root),
               'containment must resolve symlinks, not just normalise dots'
      end

      def test_a_sibling_sharing_a_prefix_is_outside
        sibling = @sandbox.join('app_root_evil')
        sibling.mkpath

        refute SafeWrite.inside?(sibling.join('x.rb'), @root)
      end

      def test_symlinked_segment_finds_an_intermediate_link
        @root.join('app').mkpath
        link = @root.join('app/components')
        File.symlink(@outside.to_s, link.to_s)

        assert_equal link.to_s,
                     SafeWrite.symlinked_segment(@root.join('app/components/senren/x.rb'), @root).to_s
      end

      def test_mkdir_p_refuses_to_build_through_a_symlink
        @root.join('app').mkpath
        File.symlink(@outside.to_s, @root.join('app/components').to_s)

        assert_raises(SafeWrite::Escape) do
          SafeWrite.mkdir_p!(@root.join('app/components/senren'), @root, 'test')
        end
      end

      def test_mkdir_p_creates_an_ordinary_directory
        SafeWrite.mkdir_p!(@root.join('app/components/senren'), @root, 'test')

        assert_predicate @root.join('app/components/senren'), :directory?
      end

      # The end-to-end version: the install itself must not write outside.
      def test_the_copier_cannot_be_redirected_through_a_symlink
        @root.join('app/components').mkpath
        FileUtils.rmdir(@root.join('app/components'))
        @root.join('app').mkpath
        File.symlink(@outside.to_s, @root.join('app/components').to_s)

        copier = ComponentCopier.new(paths: HostPaths.new(@root), stdout: StringIO.new)
        assert_raises(SafeWrite::Escape) { copier.install(['button']) }

        assert_empty Dir.children(@outside), 'nothing may be written outside the app root'
      end

      def test_a_clean_install_still_works
        copier = ComponentCopier.new(paths: HostPaths.new(@root), stdout: StringIO.new)
        copier.install(['button'])

        assert_predicate @root.join('app/components/senren/button_component.rb'), :exist?
        assert_empty Dir.children(@outside)
      end
    end
  end
end
