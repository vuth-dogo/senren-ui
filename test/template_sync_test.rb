# frozen_string_literal: true

require 'test_helper'
require 'senren/rails/host_paths'
require_relative '../scripts/template_sync'

class TemplateSyncTest < Minitest::Test
  GEM_ROOT = File.expand_path('..', __dir__)

  def setup
    @sync = TemplateSync.new(gem_root: GEM_ROOT)
  end

  def test_component_templates_map_into_the_host_component_directory
    assert_equal 'app/components/senren/button_component.html.erb',
                 destination('templates/components/button/button_component.html.erb')
    assert_equal 'app/components/senren/button_component.rb',
                 destination('templates/components/button/button_component.rb')
  end

  def test_controllers_map_into_the_namespaced_stimulus_directory
    assert_equal 'app/javascript/controllers/senren/dialog_controller.js',
                 destination('templates/controllers/dialog_controller.js')
  end

  # A registry edit can add or remove components, so no single destination can
  # express it.
  def test_registry_changes_request_a_full_reinstall
    %w[registry/components.yml registry/groups.yml registry/recipes.yml].each do |path|
      assert @sync.full_reinstall?(destination(path)), "#{path} should force a reinstall"
    end
  end

  def test_install_templates_map_to_named_host_paths
    assert_equal :host_path_base_component_path,
                 destination('lib/generators/senren/install/templates/base_component.rb.tt')
    assert_equal :host_path_stylesheet_path,
                 destination('lib/generators/senren/install/templates/senren.css.tt')
  end

  # The ledger records what is installed. Re-copying the template over it would
  # silently erase the install history.
  def test_the_installed_components_ledger_is_never_synced
    assert_nil destination('lib/generators/senren/install/templates/installed_components.yml.tt')
  end

  def test_unrelated_and_out_of_tree_paths_are_ignored
    assert_nil destination('lib/senren/rails/registry.rb')
    assert_nil destination('README.md')
    assert_nil @sync.destination_for('/etc/passwd')
    assert_nil @sync.destination_for("#{GEM_ROOT}/../outside.rb")
  end

  def test_watched_files_cover_templates_and_registry_but_not_gem_internals
    watched = @sync.watched_files.map { |path| path.delete_prefix("#{GEM_ROOT}/") }

    assert_includes watched, 'templates/components/button/button_component.rb'
    assert_includes watched, 'templates/controllers/dialog_controller.js'
    assert_includes watched, 'registry/components.yml'
    refute_includes watched, 'lib/senren/rails/registry.rb'
    assert(watched.all? { |path| File.file?(File.join(GEM_ROOT, path)) })
  end

  def test_host_path_keys_resolve_against_host_paths
    paths = Senren::Rails::HostPaths.new('/tmp/example-app')
    key = destination('lib/generators/senren/install/templates/base_component.rb.tt')

    assert @sync.host_path_key?(key)
    assert_equal paths.base_component_path, @sync.host_path_for(key, paths)
  end

  private

  def destination(relative)
    @sync.destination_for(File.join(GEM_ROOT, relative))
  end
end
