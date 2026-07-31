# frozen_string_literal: true

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

      def production_env?
        defined?(::Rails) && ::Rails.respond_to?(:env) && ::Rails.env.production?
      end

      # An asset path is only a problem when component source actually sits
      # under it, so an app that keeps sidecar assets in their own directory is
      # left alone.
      def offending_paths(app)
        components = components_dir(app)
        return [] unless components&.directory?
        return [] unless source_files?(components)

        asset_paths(app).select { |path| covers?(path, components) }
      end

      def components_dir(app)
        app.root.join('app/components')
      rescue StandardError
        nil
      end

      def source_files?(dir)
        SOURCE_EXTENSIONS.any? { |ext| Dir.glob(dir.join("**/*#{ext}")).any? }
      end

      def asset_paths(app)
        app.config.respond_to?(:assets) ? Array(app.config.assets.paths) : []
      rescue StandardError
        []
      end

      def covers?(asset_path, components)
        asset = Pathname.new(asset_path.to_s).expand_path
        components.expand_path.to_s.start_with?(asset.to_s)
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
