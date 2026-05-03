# frozen_string_literal: true

require 'senren/rails'

namespace :senren do
  desc 'Install one or more Senren components: rake senren:add[button,dialog] or bin/rails senren:add button dialog'
  task :add, [:names] => :environment do |_t, args|
    names = parse_names(args)
    options = parse_options
    abort 'Usage: bin/rails senren:add NAME [NAME...] [--client | --no-client]' if names.empty?

    paths    = Senren::Rails::HostPaths.new
    registry = Senren::Rails::Registry.load!
    copier   = Senren::Rails::ComponentCopier.new(registry: registry, paths: paths)

    installed = copier.install(names, client_override: options[:client_override], force: options[:force])

    Senren::Rails::SkillWriter.new(registry: registry, paths: paths).sync!
    Senren::Rails::AgentRulesWriter.new(registry: registry, paths: paths).sync!

    puts "Installed: #{installed.join(', ')}"
  end

  namespace :skill do
    desc 'Rebuild .senren/skill.md and refresh agent instruction adapters.'
    task sync: :environment do
      paths    = Senren::Rails::HostPaths.new
      registry = Senren::Rails::Registry.load!
      file = Senren::Rails::SkillWriter.new(registry: registry, paths: paths).sync!
      puts "Wrote #{file}"
      Senren::Rails::AgentRulesWriter.new(registry: registry, paths: paths).sync!
    end
  end

  namespace :agents do
    desc 'Regenerate .senren/agent-rules.md and adapter instruction files.'
    task sync: :environment do
      paths    = Senren::Rails::HostPaths.new
      registry = Senren::Rails::Registry.load!
      files = Senren::Rails::AgentRulesWriter.new(registry: registry, paths: paths).sync!
      files.each { |f| puts "Wrote #{f}" }
    end
  end

  namespace :llms do
    desc 'Deprecated alias for senren:agents:sync.'
    task generate: :environment do
      puts 'senren:llms:generate is deprecated. Running senren:agents:sync instead.'
      paths    = Senren::Rails::HostPaths.new
      registry = Senren::Rails::Registry.load!
      files = Senren::Rails::AgentRulesWriter.new(registry: registry, paths: paths).sync!
      files.each { |f| puts "Wrote #{f}" }
    end
  end

  desc "Run health checks against the host app's Senren installation."
  task doctor: :environment do
    ok = Senren::Rails::Doctor.new(paths: Senren::Rails::HostPaths.new).run!
    exit(1) unless ok
  end
end

# Helpers ---------------------------------------------------------------

def parse_names(args)
  raw = []
  raw.concat(args.extras)
  raw << args[:names] if args[:names]
  raw.concat(ARGV.drop_while { |a| !a.start_with?('senren:') }.drop(1))
  raw
    .flatten
    .flat_map { |s| s.to_s.split(/[,\s]+/) }
    .reject { |s| s.empty? || s.start_with?('-') }
    .uniq
end

def parse_options
  client_override =
    if ARGV.include?('--client')
      true
    elsif ARGV.include?('--no-client')
      false
    end

  { client_override: client_override, force: ARGV.include?('--force') }
end
