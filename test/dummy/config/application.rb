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
  end
end
