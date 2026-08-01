# frozen_string_literal: true

require 'senren/rails'

namespace :senren do
  desc 'Install one or more Senren components. Preferred: bin/rails senren:add button dialog. ' \
       "Legacy: bin/rails 'senren:add[button,dialog]'"
  task :add, [:names] do |_t, args|
    names = SenrenRakeArgs.names(args)
    options = SenrenRakeArgs.options

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

# Namespaced deliberately. These were top-level `def`s, which Ruby defines as
# private methods on Object — so loading this rake file gave every class in the
# host app a `parse_options` and a `parse_names`. `parse_options` is a
# plausible name for an app to define itself.
module SenrenRakeArgs
  module_function

  def names(args)
    raw = []
    raw.concat(args.extras)
    raw << args[:names] if args[:names]
    raw.concat(trailing_arguments)
    Senren::Rails::ComponentInstaller.normalize_names(raw)
  end

  def options
    words = trailing_arguments
    client_override = true if words.include?('--client')
    client_override = false if words.include?('--no-client')

    { client_override: client_override, force: words.include?('--force') }
  end

  # The words that belong to `senren:add`, and only those.
  #
  # This used to be `ARGV.drop_while { ... }.drop(1)` with no upper bound, so
  # every later argument on the command line was swallowed: `rake
  # 'senren:add[button]' db:seed` tried to install a component named "db:seed"
  # and aborted the whole invocation, and a `--force` intended for a different
  # task silently enabled overwriting here.
  def trailing_arguments
    ARGV
      .drop_while { |arg| !arg.start_with?('senren:') }
      .drop(1)
      .take_while { |arg| !rake_target?(arg) }
  end

  # A namespaced task (`db:seed`) or an environment assignment (`RAILS_ENV=x`).
  # Component names are matched by Registry::NAME_PATTERN and can contain
  # neither character.
  def rake_target?(arg)
    arg.include?(':') || arg.include?('=')
  end
end
