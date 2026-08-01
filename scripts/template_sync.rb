# frozen_string_literal: true

# Maps a file inside the gem's source tree to its destination in a seeded
# preview app, so an edit can be copied without reinstalling every component.
#
# Development tooling: this lives in scripts/ rather than lib/ because the
# gemspec ships only lib, registry, templates, and docs. Nothing here reaches a
# published gem or a host app.
class TemplateSync
  # A registry edit can add or remove components, so it cannot be resolved to a
  # single destination — it forces a full reinstall instead.
  FULL_REINSTALL = :full_reinstall

  INSTALL_TEMPLATES = {
    'base_component.rb.tt' => 'base_component_path',
    'senren.css.tt' => 'stylesheet_path',
    'conventions.md.tt' => 'conventions_file'
  }.freeze

  attr_reader :gem_root

  def initialize(gem_root:)
    @gem_root = File.expand_path(gem_root)
  end

  # bin/seed_preview copies this into the preview app, so a component added
  # after seeding rendered "Missing preview" until the app was re-seeded. It is
  # the one preview-app file that lives outside templates/.
  PREVIEW_HELPER = 'test/dummy/app/helpers/component_preview_helper.rb'

  # Every path the watcher should poll.
  def watched_files
    Dir[
      File.join(gem_root, 'templates', '**', '*'),
      File.join(gem_root, 'registry', '*.yml'),
      File.join(gem_root, 'lib', 'generators', 'senren', 'install', 'templates', '*.tt'),
      File.join(gem_root, PREVIEW_HELPER)
    ].select { |path| File.file?(path) }
  end

  # Returns a host-relative destination, FULL_REINSTALL, or nil when the file
  # has no meaningful destination.
  def destination_for(path)
    relative = relative_path(path)
    return nil unless relative

    case relative
    when PREVIEW_HELPER then 'app/helpers/component_preview_helper.rb'
    when %r{\Aregistry/} then FULL_REINSTALL
    when %r{\Atemplates/controllers/(.+_controller\.js)\z}
      "app/javascript/controllers/senren/#{Regexp.last_match(1)}"
    when %r{\Atemplates/components/[^/]+/(.+)\z}
      "app/components/senren/#{Regexp.last_match(1)}"
    when %r{\Alib/generators/senren/install/templates/(.+)\z}
      install_template_key(Regexp.last_match(1))
    end
  end

  # `installed_components.yml.tt` is deliberately absent from INSTALL_TEMPLATES:
  # the ledger is state, not a template, and re-copying it would wipe the
  # install history.
  def install_template_key(basename)
    key = INSTALL_TEMPLATES[basename]
    return nil unless key

    :"host_path_#{key}"
  end

  def host_path_for(key, paths)
    paths.public_send(key.to_s.delete_prefix('host_path_'))
  end

  def full_reinstall?(destination)
    destination == FULL_REINSTALL
  end

  def host_path_key?(destination)
    destination.is_a?(Symbol) && destination != FULL_REINSTALL
  end

  private

  def relative_path(path)
    expanded = File.expand_path(path)
    prefix = "#{gem_root}/"
    return nil unless expanded.start_with?(prefix)

    expanded.delete_prefix(prefix)
  end
end
