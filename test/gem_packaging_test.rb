# frozen_string_literal: true

require 'test_helper'
require 'rubygems/package'
require 'stringio'

# What ships to rubygems.org is a public contract, and it is easy to break
# silently: a new directory is added, the glob picks it up, and development
# tooling reaches every consumer. Nothing verified that before this file.
class GemPackagingTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def spec
    @spec ||= Dir.chdir(ROOT) { Gem::Specification.load('senren-ui.gemspec') }
  end

  def test_the_gemspec_is_valid
    Dir.chdir(ROOT) { spec.validate(false) }
  end

  def test_runtime_dependencies_are_minimal_and_intentional
    names = spec.runtime_dependencies.map(&:name).sort

    assert_equal %w[rails view_component], names,
                 'a UI library that copies source should not pull extra gems into every host app'
  end

  # nokogiri is used only by component tests to parse rendered HTML. Shipping it
  # as a runtime dependency would force every consumer to build a native
  # extension for a gem that never parses HTML.
  def test_nokogiri_is_not_a_runtime_dependency
    refute_includes spec.runtime_dependencies.map(&:name), 'nokogiri'
  end

  def test_ships_the_directories_consumers_need
    %w[
      lib/senren/rails.rb
      lib/senren/rails/component_copier.rb
      lib/generators/senren/install/install_generator.rb
      lib/generators/senren/install/templates/base_component.rb.tt
      lib/tasks/senren.rake
      registry/components.yml
      templates/components/button/button_component.rb
      templates/controllers/dialog_controller.js
      README.md
      CHANGELOG.md
      LICENSE
    ].each do |path|
      assert_includes spec.files, path, "#{path} must ship"
    end
  end

  # Development tooling must never reach a consumer's machine.
  def test_excludes_development_and_test_material
    offenders = spec.files.select do |path|
      path.start_with?('bin/', 'scripts/', 'test/', 'gemfiles/', '.github/', 'history/', 'plans/', '.local/')
    end

    assert_empty offenders, "development-only paths leaked into the gem: #{offenders.join(', ')}"
  end

  # Documentation may describe the preview-app reload endpoint; docs/hot_reload.md
  # does, and that section is written for consumers. What must never ship is the
  # executable plumbing itself.
  def test_ships_no_executable_hot_reload_plumbing
    leaked = spec.files.reject { |path| path.end_with?('.md') }.select do |path|
      full = File.join(ROOT, path)
      File.file?(full) && File.read(full).match?(/reload_token|__senrenPerf/)
    end

    assert_empty leaked, "preview-app reload plumbing must stay local: #{leaked.join(', ')}"
  end

  def test_every_declared_file_exists
    missing = spec.files.reject { |path| File.file?(File.join(ROOT, path)) }

    assert_empty missing, "gemspec lists files that do not exist: #{missing.join(', ')}"
  end

  def test_the_package_actually_builds
    Dir.mktmpdir do |dir|
      built = Dir.chdir(ROOT) do
        silence_stdout { Gem::Package.build(spec, false, false, File.join(dir, 'senren-ui.gem')) }
      end

      assert File.file?(File.join(ROOT, built)) || File.file?(built), 'gem build produced no file'
    ensure
      candidate = File.join(ROOT, "senren-ui-#{spec.version}.gem")
      FileUtils.rm_f(candidate)
    end
  end

  # The gemspec advertises a Ruby floor; CI must exercise it, or the claim is
  # decoration. See plans/022_jet_ui_lessons.md.
  def test_supported_versions_are_covered_by_the_ci_matrix
    workflow = YAML.safe_load_file(File.join(ROOT, '.github/workflows/ci.yml'), aliases: true)
    matrix = workflow.dig('jobs', 'matrix', 'strategy', 'matrix')

    refute_nil matrix, 'CI must define a version matrix'

    floor = Gem::Version.new(spec.required_ruby_version.requirements.first.last.to_s)
    tested = matrix.fetch('ruby').map { |v| Gem::Version.new(v) }

    assert_includes tested, floor,
                    "required_ruby_version floor #{floor} is not in the CI matrix #{matrix['ruby']}"

    rails_floor = spec.dependencies.find { |d| d.name == 'rails' }.requirement.requirements.first.last.to_s

    assert_includes matrix.fetch('rails'), rails_floor.split('.').first(2).join('.'),
                    "rails floor #{rails_floor} is not in the CI matrix #{matrix['rails']}"
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def test_a_gemfile_exists_for_every_matrix_rails_version
    workflow = YAML.safe_load_file(File.join(ROOT, '.github/workflows/ci.yml'), aliases: true)
    versions = workflow.dig('jobs', 'matrix', 'strategy', 'matrix', 'rails')

    versions.each do |version|
      assert_path_exists File.join(ROOT, "gemfiles/rails_#{version}.gemfile")
    end
  end
end
