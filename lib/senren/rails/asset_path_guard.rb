# frozen_string_literal: true

require 'pathname'

module Senren
  module Rails
    # Refuses to let component source be served as a static asset.
    #
    # ViewComponent documents putting sidecar assets next to components, and the
    # usual way to reach them is:
    #
    #   config.assets.paths << Rails.root.join("app/components")
    #
    # With Propshaft that one line makes every file under app/components a
    # servable asset, `.rb` and `.html.erb` included. Verified against Propshaft
    # 1.3.2: 129 component source files resolved, `assets:precompile` copied all
    # of them into public/assets/, and public/assets/.manifest.json listed each
    # logical path next to its digested filename — so the digest is not even an
    # obstacle. In production the web server hands them out with Rails never
    # involved.
    #
    # Development is a different risk calculation, so there it warns. Production
    # raises: a boot failure is recoverable, published source is not.
    module AssetPathGuard
      SOURCE_EXTENSIONS = %w[.rb .erb].freeze

      module_function

      # `production:` is injected rather than read from ::Rails so the guard can
      # be unit tested without booting Rails, which is how the rest of this
      # library's unit suite runs.
      def check!(app, io: $stderr, production: production_env?)
        offenders = offending_paths(app)
        return true if offenders.empty?

        message = message_for(offenders)
        raise message if production

        io.puts("[senren] WARNING: #{message}")
        false
      end

      # Fails closed. `Rails.env.production?` let a conventional
      # RAILS_ENV=staging deploy print one line of stderr and precompile the
      # source anyway, and the same held for review apps and any custom
      # environment name. `local?` is true only for development and test — the
      # two environments where exposure is acceptable — so everything else is
      # treated as deployed. Available since Rails 7.1, which is the floor.
      def production_env?
        return false unless defined?(::Rails) && ::Rails.respond_to?(:env)
        return !::Rails.env.local? if ::Rails.env.respond_to?(:local?)

        !%w[development test].include?(::Rails.env.to_s)
      end

      # An asset path is only a problem when component source actually sits
      # under it, so an app that keeps sidecar assets in their own directory is
      # left alone.
      def offending_paths(app)
        components = components_dir(app)
        return [] unless components&.directory?

        sources = component_sources(components)
        return [] if sources.empty?

        asset_paths(app).select { |path| publishes_source?(path, sources) }
      end

      # Propshaft follows directory and file symlinks when collecting assets.
      # Compare their real targets, including links nested below an asset path,
      # so an alias cannot publish source past the production boot guard.
      def publishes_source?(asset_path, sources)
        asset = Pathname.new(asset_path.to_s).expand_path
        return false unless asset.directory?

        each_file(asset).any? { |_, target| sources.key?(target) }
      end

      def components_dir(app)
        app.root.join('app/components')
      rescue StandardError
        nil
      end

      def component_sources(components)
        each_file(components).with_object({}) do |(path, target), sources|
          sources[target] = true if [path.extname, target.extname].any? { |ext| SOURCE_EXTENSIONS.include?(ext) }
        end
      end

      # Track real directory identities so aliases and cycles are visited once.
      # Keep the original filename as well: widget.rb may point to a differently
      # named file outside app/components, which is still component source.
      def each_file(path, visited = {}, &block)
        return enum_for(__method__, path, visited) unless block

        target = path.realpath
        if target.directory?
          return if visited[target]

          visited[target] = true
          target.children.each { |child| each_file(child, visited, &block) }
        else
          block.call(path, target)
        end
      rescue Errno::ENOENT, Errno::ENOTDIR, Errno::ELOOP
        # Broken links cannot publish content; visited directories stop cycles.
        nil
      end

      def asset_paths(app)
        app.config.respond_to?(:assets) ? Array(app.config.assets.paths) : []
      rescue StandardError
        []
      end

      def message_for(offenders)
        <<~MESSAGE.strip
          app/components is on the asset load path (#{offenders.join(', ')}).

          Propshaft serves every file under an asset path, so your component
          .rb and .html.erb source would be published — assets:precompile copies
          them into public/assets and .manifest.json lists them by name.

          Move sidecar assets into their own directory and add that instead, for
          example app/components/assets rather than app/components.
        MESSAGE
      end
    end
  end
end
