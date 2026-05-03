#!/usr/bin/env ruby
# Seeds apps/site with the full Senren install + every registry component.
# Mirrors the seed_todolist.rb pattern but installs ALL components so the
# documentation site can render previews for every entry in the registry.

require 'fileutils'

GEM_ROOT  = File.expand_path('..', __dir__)
HOST_ROOT = File.expand_path('../apps/site', GEM_ROOT)

$LOAD_PATH.unshift File.join(GEM_ROOT, 'lib')

require 'senren/rails/version'
require 'senren/rails/registry'
require 'senren/rails/host_paths'
require 'senren/rails/component_copier'
require 'senren/rails/skill_writer'
require 'senren/rails/agent_rules_writer'

module Senren
  module Rails
    GEM_ROOT_OVERRIDE = ::GEM_ROOT
    def self.gem_root        = GEM_ROOT_OVERRIDE
    def self.registry_path   = File.join(GEM_ROOT_OVERRIDE, 'registry/components.yml')
    def self.groups_path     = File.join(GEM_ROOT_OVERRIDE, 'registry/groups.yml')
    def self.recipes_path    = File.join(GEM_ROOT_OVERRIDE, 'registry/recipes.yml')
    def self.templates_root  = File.join(GEM_ROOT_OVERRIDE, 'templates')
  end
end

paths = Senren::Rails::HostPaths.new(HOST_ROOT)
paths.ensure_dirs!

inst_tpl_root = File.join(GEM_ROOT, 'lib/generators/senren/install/templates')
{
  'base_component.rb.tt' => paths.base_component_path,
  'senren.css.tt' => paths.stylesheet_path,
  'conventions.md.tt' => paths.conventions_file,
  'installed_components.yml.tt' => paths.installed_components
}.each do |tpl, dest|
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(File.join(inst_tpl_root, tpl), dest)
  puts "  copy  #{dest}"
end

FileUtils.mkdir_p(paths.registry_mirror.dirname)
FileUtils.cp(Senren::Rails.registry_path, paths.registry_mirror)
puts "  copy  #{paths.registry_mirror}"

registry  = Senren::Rails::Registry.load!
all       = registry.all.map(&:name)
copier    = Senren::Rails::ComponentCopier.new(registry: registry, paths: paths)
installed = copier.install(all, force: true)
puts "  installed components: #{installed.size}"

skill = Senren::Rails::SkillWriter.new(registry: registry, paths: paths).sync!
puts "  wrote #{skill}"

agent_files = Senren::Rails::AgentRulesWriter.new(registry: registry, paths: paths).sync!
agent_files.each { |f| puts "  wrote #{f}" }
