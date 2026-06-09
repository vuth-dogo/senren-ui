# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'senren/rails'
require 'senren/rails/registry'

class SeedPreviewTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir
    prepare_host_app_skeleton
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
  end

  def test_seed_preview_writes_preview_host_files
    registry = Senren::Rails::Registry.load!

    stdout, stderr, status = Open3.capture3(
      { 'SENREN_PREVIEW_ROOT' => @root },
      'ruby',
      File.expand_path('../bin/seed_preview', __dir__),
      chdir: File.expand_path('..', __dir__)
    )

    assert status.success?, stderr
    assert_includes stdout, "installed components: #{registry.names.size}"
    assert_file_includes 'config/routes.rb', 'root "components#index"'
    assert_file_includes 'app/controllers/components_controller.rb',
                         'class ComponentsController < ApplicationController'
    assert_file_includes 'app/helpers/component_preview_helper.rb', 'def preview_component_names'
    assert_file_includes 'app/helpers/component_preview_helper.rb', 'def render_component_preview(name)'
    assert_file_includes 'app/views/components/index.html.erb', 'preview_component_names.each do |name|'
    assert_file_includes 'app/views/components/index.html.erb', 'render_component_preview(name)'
    assert_file_includes 'Gemfile', %(gem "senren-ui", path: "#{File.expand_path('..', __dir__)}")
    assert_file_includes 'app/views/layouts/application.html.erb', '@tailwindcss/browser@4'
    assert_file_includes 'app/views/layouts/application.html.erb', 'bg-[hsl(var(--senren-background))]'
    assert_file_includes 'app/views/layouts/application.html.erb', 'stylesheet_link_tag "senren"'
    assert_file_includes 'app/views/layouts/application.html.erb', 'type="importmap"'
    assert_file_includes 'app/views/layouts/application.html.erb', '/application.js'
    assert File.exist?(File.join(@root, 'public/stimulus.js'))
    assert File.exist?(File.join(@root, 'public/application.js'))
    assert File.exist?(File.join(@root, 'public/controllers/senren/dialog_controller.js'))
    assert File.exist?(File.join(@root, 'app/components/senren/button_component.rb'))
    assert File.exist?(File.join(@root, 'app/components/senren/rich_text_editor_lite_component.rb'))
    assert File.exist?(File.join(@root, 'app/javascript/controllers/senren/dialog_controller.js'))
    assert File.exist?(File.join(@root, 'app/assets/stylesheets/senren.css'))
  end

  private

  def prepare_host_app_skeleton
    FileUtils.mkdir_p(File.join(@root, 'bin'))
    FileUtils.mkdir_p(File.join(@root, 'config'))
    FileUtils.mkdir_p(File.join(@root, 'app/assets/stylesheets'))
    FileUtils.mkdir_p(File.join(@root, 'app/views/layouts'))

    File.write(File.join(@root, 'bin/rails'), "#!/usr/bin/env ruby\n")
    File.write(File.join(@root, 'Gemfile'), %(gem "senren-ui", path: "../..", require: "senren/rails"\n))
    File.write(File.join(@root, 'config/routes.rb'), <<~RUBY)
      Rails.application.routes.draw do
        # root "posts#index"
      end
    RUBY
    File.write(File.join(@root, 'app/assets/stylesheets/application.css'), "/* app styles */\n")
    File.write(File.join(@root, 'app/views/layouts/application.html.erb'), <<~ERB)
      <!DOCTYPE html>
      <html>
        <head>
          <%= stylesheet_link_tag :app %>
        </head>
        <body>
          <%= yield %>
        </body>
      </html>
    ERB
  end

  def assert_file_includes(path, expected)
    assert_includes File.read(File.join(@root, path)), expected
  end

  def refute_file_includes(path, unexpected)
    refute_includes File.read(File.join(@root, path)), unexpected
  end
end
