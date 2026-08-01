# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Senren
  module Rails
    # Containment for everything this gem writes into a host app.
    #
    # The threat model is a repository you clone and run `senren:install` in.
    # The *content* written is gem-controlled, so this is a file-creation and
    # overwrite primitive rather than an arbitrary-content write — but a
    # checkout that ships `app/components/senren` as a symlink pointing outside
    # the project could previously redirect every copied file, and
    # `write_adapter_file` reads its destination before rewriting it, so
    # pre-existing content outside the checkout was modified too.
    #
    # Two independent defects made that possible, and both are fixed here:
    #
    #   1. Containment used Pathname#expand_path, which normalises `..`
    #      lexically and does NOT resolve symlinks. An escaping path therefore
    #      passed the start_with? check. Containment must compare realpath.
    #   2. Symlinks were refused on the leaf only, never on an intermediate
    #      directory, and Pathname#mkpath stops at File.directory? — which
    #      follows a link — so a symlinked parent was preserved rather than
    #      replaced.
    module SafeWrite
      class Escape < StandardError; end

      module_function

      # The deepest existing ancestor of `path`, with every symlink resolved.
      # Resolving the parent rather than the path itself matters because the
      # file being written usually does not exist yet.
      def real_ancestor(path)
        current = Pathname.new(path).expand_path
        current = current.parent until current.exist? || current.root?
        current.realpath
      rescue SystemCallError
        current
      end

      # True when `path` resolves inside `root` once symlinks are followed.
      def inside?(path, root)
        real_root = Pathname.new(root).expand_path
        real_root = real_root.realpath if real_root.exist?
        ancestor = real_ancestor(path)

        ancestor == real_root || ancestor.to_s.start_with?("#{real_root}#{File::SEPARATOR}")
      end

      def assert_inside!(path, root, label)
        return Pathname.new(path).expand_path if inside?(path, root)

        raise Escape,
              "Refusing to write outside the app root: #{path} resolves to " \
              "#{real_ancestor(path)} (#{label})"
      end

      # A symlink anywhere between root and path redirects the write, so the
      # whole chain is checked rather than the leaf alone.
      def symlinked_segment(path, root)
        real_root = Pathname.new(root).expand_path
        candidate = Pathname.new(path).expand_path
        chain = []
        while candidate != real_root && candidate.to_s.length > real_root.to_s.length
          chain << candidate
          candidate = candidate.parent
        end
        chain.find { |segment| File.symlink?(segment) }
      end

      # Creates `dir` without ever writing through a symlinked ancestor.
      def mkdir_p!(dir, root, label)
        if (link = symlinked_segment(dir, root))
          raise Escape, "Refusing to create #{dir}: #{link} is a symlink (#{label})"
        end

        assert_inside!(dir, root, label)
        FileUtils.mkdir_p(dir)
        dir
      end

      # Resolves a destination for writing, or returns nil when it must be
      # skipped. Raises when the destination escapes the app root.
      def resolve(dest, root, label, io: $stdout)
        if (link = symlinked_segment(dest, root))
          io.puts "  skip  #{dest} (#{link} is a symlink; refusing to write through it) [#{label}]"
          return nil
        end

        assert_inside!(dest, root, label)
      end

      # Contained and not reached through a link, anywhere in the chain.
      #
      # assert_inside! alone is not enough for a file that is itself a symlink:
      # it resolves the deepest EXISTING ancestor, and a *dangling* symlink is
      # skipped by `exist?`, so the check would clear the parent directory and
      # the write would still land on the link's target. symlinked_segment uses
      # File.symlink?, which does not follow, and covers the leaf.
      def assert_writable!(path, root, label)
        if (link = symlinked_segment(path, root))
          raise Escape, "Refusing to write #{path}: #{link} is a symlink (#{label})"
        end

        assert_inside!(path, root, label)
      end

      # Every write this gem performs goes through here or #copy!.
      #
      # Hand-rolled File.write / FileUtils.cp is what let component source
      # escape twice: once through a symlinked directory, and once -- after
      # that was fixed -- through a symlinked destination *file*, because
      # containment had been applied to the parent only. Writing via a
      # temporary and renaming also means a killed process cannot truncate the
      # file: rename is atomic and does not follow a symlink at the target.
      def write!(path, content, root, label)
        target = assert_writable!(path, root, label)
        atomically(target) { |tmp| File.write(tmp, content) }
      end

      def copy!(source, path, root, label)
        target = assert_writable!(path, root, label)
        atomically(target) { |tmp| FileUtils.cp(source, tmp) }
      end

      def atomically(target)
        tmp = Pathname.new("#{target}.#{Process.pid}.tmp")
        yield tmp
        File.rename(tmp, target)
        target
      ensure
        FileUtils.rm_f(tmp) if tmp&.exist?
      end
    end
  end
end
