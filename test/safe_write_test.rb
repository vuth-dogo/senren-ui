# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'senren/rails'
require 'senren/rails/safe_write'
require 'senren/rails/host_paths'
require 'senren/rails/component_copier'
require 'senren/rails/component_installer'

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

      # The property is containment, not the absence of symlinks. Refusing
      # every link regardless of where it pointed broke `ln -s AGENTS.md
      # CLAUDE.md` -- an ordinary way to keep one set of agent instructions --
      # and took the whole senren:add command down with it. Every symlink test
      # above this used a link pointing OUTSIDE, so the in-repo direction had
      # never been exercised.
      def test_a_symlink_that_stays_inside_the_root_is_allowed
        @root.join('docs').mkpath
        @root.join('docs/NOTES.md').write("# notes\n")
        File.symlink('docs/NOTES.md', @root.join('CLAUDE.md').to_s)

        assert SafeWrite.inside?(@root.join('CLAUDE.md'), @root)
      end

      def test_a_symlinked_directory_that_stays_inside_the_root_is_allowed
        @root.join('config/senren').mkpath
        File.symlink('config/senren', @root.join('.senren').to_s)

        assert SafeWrite.inside?(@root.join('.senren/registry.yml'), @root)
      end

      # Writing to what the link points at, rather than replacing the link,
      # is what lets a deliberate in-repo link survive an install.
      def test_writing_through_an_in_repo_link_preserves_it
        @root.join('docs').mkpath
        @root.join('docs/NOTES.md').write("old\n")
        File.symlink('docs/NOTES.md', @root.join('CLAUDE.md').to_s)

        SafeWrite.write!(@root.join('CLAUDE.md'), "new\n", @root, 'test')

        assert_predicate @root.join('CLAUDE.md'), :symlink?
        assert_equal "new\n", @root.join('docs/NOTES.md').read
      end

      def test_mkdir_p_refuses_to_build_through_a_symlink_pointing_outside
        @root.join('app').mkpath
        File.symlink(@outside.to_s, @root.join('app/components').to_s)

        assert_raises(SafeWrite::Escape) do
          SafeWrite.mkdir_p!(@root.join('app/components/senren'), @root, 'test')
        end
      end

      def test_mkdir_p_accepts_a_symlink_pointing_inside
        @root.join('real').mkpath
        File.symlink('real', @root.join('linked').to_s)

        SafeWrite.mkdir_p!(@root.join('linked/nested'), @root, 'test')

        assert_predicate @root.join('real/nested'), :directory?
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

      # The follow-up finding, and the sharper one: fixing directory containment
      # left every write whose DESTINATION FILE was the symlink. Worse, the
      # registry-mirror path was introduced by the fix for a different finding,
      # reusing the FileUtils.cp shape of the Installer#mirror_registry that had
      # just been deleted for the same defect. Moving a bug is not fixing it.
      #
      # All four writes are pinned, so the next one cannot regress alone.
      SYMLINKED_TARGETS = {
        '.senren/registry.yml' => "outside: registry\n",
        '.senren/installed_components.yml' => "installed: []\nmine: keep\n",
        'CLAUDE.md' => "# my notes\n",
        'AGENTS.md' => "# my notes\n"
      }.freeze

      def test_no_write_follows_a_symlinked_destination_file
        SYMLINKED_TARGETS.each do |relative, seed|
          # A fresh root per target: an earlier iteration writes real files, and
          # reusing the root would collide rather than test anything.
          FileUtils.rm_rf(@root)
          @root.mkpath

          victim = @outside.join(File.basename(relative))
          victim.write(seed)
          @root.join(File.dirname(relative)).mkpath
          File.symlink(victim.to_s, @root.join(relative).to_s)

          assert_raises(SafeWrite::Escape, "#{relative} must be refused") { install }
          assert_equal seed, victim.read, "#{relative} was written through the symlink"
        end
      end

      # A dangling link is skipped by File.exist?, so a check that resolved only
      # existing ancestors would clear the parent directory and let the write
      # land on the link's target. real_target reads the DECLARED target with
      # File.readlink, which works whether or not it exists.
      def test_a_dangling_symlink_pointing_outside_is_refused
        ghost = @outside.join('ghost.yml')
        @root.join('.senren').mkpath
        File.symlink(ghost.to_s, @root.join('.senren/registry.yml').to_s)

        assert_raises(SafeWrite::Escape) { install }
        refute_path_exists ghost, 'a dangling symlink must not become a file outside the root'
      end

      # Two adapters sharing one file is a real conflict -- they get different
      # content, so the last write silently wins -- but it is not an escape, and
      # it must be reported as what it is. It also has to be caught before the
      # copier runs: the first version failed with components already on disk.
      def test_two_agent_adapters_sharing_a_file_fail_before_anything_is_written
        @root.join('AGENTS.md').write("# my notes\n")
        File.symlink('AGENTS.md', @root.join('CLAUDE.md').to_s)

        error = assert_raises(ArgumentError) { install }

        assert_match(/cannot share a file/, error.message)
        assert_match(/AGENTS\.md and CLAUDE\.md/, error.message)
        refute_path_exists @root.join('app/components/senren/button_component.rb'),
                           'nothing may be copied before the preflight fails'
        refute_path_exists @root.join('.senren/installed_components.yml'),
                           'the ledger must not be written before the preflight fails'
      end

      def test_an_install_into_a_repo_with_a_harmless_symlink_succeeds
        @root.join('docs').mkpath
        @root.join('docs/NOTES.md').write("# notes\n")
        File.symlink('docs/NOTES.md', @root.join('CLAUDE.md').to_s)

        install

        assert_predicate @root.join('app/components/senren/button_component.rb'), :exist?
        assert_empty Dir.children(@outside)
      end

      # A guard nobody can satisfy gets deleted, so the legitimate case is
      # pinned next to the refusals.
      def test_an_ordinary_install_writes_all_of_them
        install

        assert_predicate @root.join('.senren/registry.yml'), :exist?
        assert_predicate @root.join('.senren/installed_components.yml'), :exist?
        assert_predicate @root.join('CLAUDE.md'), :exist?
        assert_empty Dir.children(@outside)
      end

      # `IndexError: string not matched` from String#[]= told the user nothing.
      def test_a_ledger_that_is_not_a_mapping_fails_clearly
        @root.join('.senren').mkpath
        @root.join('.senren/installed_components.yml').write("just a string\n")

        error = assert_raises(ArgumentError) { install }

        assert_match(/not a Senren ledger/, error.message)
      end

      def install
        ComponentInstaller.new(paths: HostPaths.new(@root), stdout: StringIO.new)
                          .install(names: ['button'])
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
