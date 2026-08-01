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

      MAX_LINK_DEPTH = 32

      # Where a write to `path` would actually land, with symlinks followed --
      # including a DANGLING one, by reading its declared target rather than
      # asking the filesystem to resolve it.
      #
      # Following the declared target is what makes the dangling case decidable.
      # `exist?` is false on a broken link, so a check that resolved only
      # existing ancestors would clear the parent directory and let the write
      # land wherever the link points.
      def real_target(path, depth = 0)
        current = Pathname.new(path).expand_path
        return current if depth > MAX_LINK_DEPTH

        if current.symlink?
          link = Pathname.new(File.readlink(current))
          link = current.dirname + link unless link.absolute?
          return real_target(link, depth + 1)
        end
        return current.realpath if current.exist?

        resolve_existing_prefix(current)
      rescue SystemCallError
        Pathname.new(path).expand_path
      end

      # For a destination that does not exist yet: resolve the deepest ancestor
      # that does, then re-append the part that is still missing.
      def resolve_existing_prefix(path)
        tail = []
        current = path
        until current.exist? || current.root?
          tail.unshift(current.basename)
          current = current.parent
        end
        current = current.realpath if current.exist?
        tail.reduce(current) { |acc, part| acc.join(part) }
      end

      # True when a write to `path` would land inside `root`.
      #
      # The property is containment, NOT the absence of symlinks. An earlier
      # version refused every link on the path regardless of where it pointed,
      # which broke `ln -s AGENTS.md CLAUDE.md` -- an ordinary way to keep one
      # set of agent instructions -- and took `senren:add` down with it.
      def inside?(path, root)
        real_root = Pathname.new(root).expand_path
        real_root = real_root.realpath if real_root.exist?
        target = real_target(path)

        target == real_root || target.to_s.start_with?("#{real_root}#{File::SEPARATOR}")
      end

      def assert_inside!(path, root, label)
        return real_target(path) if inside?(path, root)

        raise Escape,
              "Refusing to write outside the app root: #{path} resolves to " \
              "#{real_target(path)} (#{label})"
      end

      # Creates `dir`, refusing only when it would land outside the root.
      def mkdir_p!(dir, root, label)
        target = assert_inside!(dir, root, label)
        FileUtils.mkdir_p(target)
        target
      end

      # Resolves a destination for writing, or returns nil when it must be
      # skipped. Raises when the destination escapes the app root.
      def resolve(dest, root, label, io: $stdout)
        assert_inside!(dest, root, label)
      rescue Escape => e
        io.puts "  skip  #{dest} (#{e.message}) [#{label}]"
        nil
      end

      # An in-repo symlink is left in place: the write goes to what it points
      # at, so `ln -s AGENTS.md CLAUDE.md` survives the write instead of being
      # replaced by a regular file.
      def assert_writable!(path, root, label)
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
