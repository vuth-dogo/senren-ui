# frozen_string_literal: true

require 'senren/rails'

namespace :senren do
  desc 'Install one or more Senren components. Preferred: bin/rails senren:add button dialog. ' \
       "Legacy: bin/rails 'senren:add[button,dialog]'"
  task :add, [:names] do |_t, args|
    names = parse_names(args)
    options = parse_options

    Senren::Rails::ComponentInstaller.new.install(
      names: names,
      client_override: options[:client_override],
      force: options[:force]
    )
  rescue ArgumentError => e
    abort e.message
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
  Senren::Rails::ComponentInstaller.normalize_names(raw)
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
