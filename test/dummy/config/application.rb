require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'view_component'
require 'view_component/engine'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults 7.1

    config.eager_load = false
    config.hosts.clear
    config.secret_key_base = 'dummy-secret-key-base'
    config.session_store :cookie_store, key: '_senren_dummy_session'
    config.autoload_paths << root.join('app/helpers')

    # What a host app that ran `bin/rails senren:locales vi` has: the shipped
    # Vietnamese file, loaded like any other. English needs nothing, which is the
    # point - every component carries its English as the default.
    config.i18n.load_path << File.expand_path('../../../templates/locales/senren.vi.yml', __dir__)
    config.i18n.available_locales = %i[en vi]
  end
end
