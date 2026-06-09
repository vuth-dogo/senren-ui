# frozen_string_literal: true

require 'senren/rails/version'

module Senren
  module Rails
    GEM_ROOT = File.expand_path('../..', __dir__).freeze

    autoload :Registry,         'senren/rails/registry'
    autoload :ComponentCopier,  'senren/rails/component_copier'
    autoload :ComponentInstaller, 'senren/rails/component_installer'
    autoload :SkillWriter,      'senren/rails/skill_writer'
    autoload :AgentRulesWriter, 'senren/rails/agent_rules_writer'
    autoload :LlmsWriter,       'senren/rails/llms_writer'
    autoload :Installer,        'senren/rails/installer'
    autoload :Doctor,           'senren/rails/doctor'
    autoload :HostPaths,        'senren/rails/host_paths'

    def self.gem_root
      GEM_ROOT
    end

    def self.registry_path
      File.join(GEM_ROOT, 'registry', 'components.yml')
    end

    def self.groups_path
      File.join(GEM_ROOT, 'registry', 'groups.yml')
    end

    def self.recipes_path
      File.join(GEM_ROOT, 'registry', 'recipes.yml')
    end

    def self.templates_root
      File.join(GEM_ROOT, 'templates')
    end
  end
end

require 'senren/rails/engine' if defined?(Rails::Engine)
