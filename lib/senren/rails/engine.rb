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
    end
  end
end
