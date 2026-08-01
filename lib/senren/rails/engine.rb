# frozen_string_literal: true

require 'rails/engine'

module Senren
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Senren

      initializer 'senren.rails.load_tasks' do |app|
        rake_path = File.expand_path('../../tasks/senren.rake', __dir__)
        app.paths['lib/tasks'] << rake_path if File.exist?(rake_path)
      end

      # The gem's only production-boot behaviour, and it earns the exception:
      # with app/components on the asset load path, Propshaft publishes
      # component source.
      #
      # after_initialize rather than an `after:` anchor. Hosts append asset
      # paths from config/initializers/assets.rb, so the check has to see a
      # fully configured app. after_initialize is the only placement that
      # guarantees that without reasoning about railtie order.
      #
      # This was first written as `after: :append_assets_path`, copied from
      # sprockets-rails. Propshaft names its equivalent
      # "propshaft.append_assets_path", and Rails resolves an unknown ordering
      # anchor to an empty dependency set rather than raising — so the anchor
      # was inert. It happened not to matter, because an application's own
      # initializers run ahead of every engine's, but an inert anchor that reads
      # like a guarantee is worse than no anchor.
      initializer 'senren.rails.guard_asset_paths' do |app|
        app.config.after_initialize do
          require 'senren/rails/asset_path_guard'
          Senren::Rails::AssetPathGuard.check!(app)
        end
      end
    end
  end
end
