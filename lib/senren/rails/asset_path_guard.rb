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

        asset_paths(app).select { |path| publishes_source?(path, components) }
      end

      # Whether serving this asset path would serve component source.
      #
      # `source_files?` used to be asked once about app/components as a whole,
      # which is the wrong question for a descendant path: with that shape,
      # app/components/assets holding nothing but CSS looked identical to
      # app/components/senren holding every component. Only the overlapping
      # subtree can publish anything, and that subtree is the deeper of the two
      # paths.
      def publishes_source?(asset_path, components)
        asset = Pathname.new(asset_path.to_s).expand_path
        components = components.expand_path
        return false unless overlap?(asset, components)

        source_files?(asset.to_s.length >= components.to_s.length ? asset : components)
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

      # Two paths overlap when one contains the other, in EITHER direction, and
      # the test has to be separator-aware:
      #
      #   app/components         is an ancestor  -> publishes everything
      #   app/components/senren  is a descendant -> publishes the components
      #   app/comp               shares a prefix -> publishes nothing
      #
      # The first version tested only the ancestor direction with a bare
      # start_with?, so it missed the descendant case — which is what a
      # developer writes after reading this module's own remediation text — and
      # it blocked production boots over an unrelated app/comp directory.
      def overlap?(one, other)
        a = "#{one}#{File::SEPARATOR}"
        b = "#{other}#{File::SEPARATOR}"

        a.start_with?(b) || b.start_with?(a)
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
