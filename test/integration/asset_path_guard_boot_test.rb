# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'

module Senren
  # The unit test for AssetPathGuard drives it with a Struct that mimics a Rails
  # application. That is fast and precise, but it cannot answer the question
  # that matters: does the guard fire during a real boot, against a real
  # Propshaft, reading a real config/initializers/assets.rb?
  #
  # These do, in a subprocess, because Rails can only be initialized once per
  # process. The disclosure they defend against was reproduced first: with
  # app/components on the asset path, `RAILS_ENV=production assets:precompile`
  # copied component .rb and .html.erb into public/assets, listed them in
  # .manifest.json, and the web server served them with HTTP 200.
  class AssetPathGuardBootTest < Minitest::Test
    OFFENDING_INITIALIZER = <<~RUBY
      Rails.application.config.assets.paths << Rails.root.join("app/components")
    RUBY

    def setup
      @root = Dir.mktmpdir('senren-guard-boot')
      @railties_order = nil
      seed_app
    end

    def teardown
      FileUtils.remove_entry(@root) if @root && Dir.exist?(@root)
    end

    def test_development_warns_but_still_boots
      offend!
      result = boot('development')

      assert_equal 'booted', result[:status], result[:stderr]
      assert_includes result[:stderr], 'app/components is on the asset load path'
    end

    def test_production_refuses_to_boot
      offend!
      result = boot('production')

      assert_equal 'raised', result[:status], result[:stdout]
      assert_includes result[:stdout], 'app/components is on the asset load path'
    end

    def test_a_conventional_app_boots_silently_in_production
      result = boot('production')

      assert_equal 'booted', result[:status], result[:stdout]
      refute_includes result[:stderr], 'asset load path'
    end

    def test_a_conventional_app_boots_silently_in_development
      result = boot('development')

      assert_equal 'booted', result[:status], result[:stdout]
      refute_includes result[:stderr], 'asset load path'
    end

    # Sidecar assets are a legitimate ViewComponent pattern. The guard objects to
    # publishing source, not to sidecar assets, so a dedicated subdirectory has
    # to stay allowed or people will just delete the guard.
    def test_a_dedicated_sidecar_asset_directory_is_allowed
      FileUtils.mkdir_p(File.join(@root, 'app/components/assets'))
      File.write(File.join(@root, 'app/components/assets/senren.css'), ".senren{}\n")
      File.write(File.join(@root, 'config/initializers/assets.rb'), <<~RUBY)
        Rails.application.config.assets.paths << Rails.root.join("app/components/assets")
      RUBY

      result = boot('production')

      assert_equal 'booted', result[:status], result[:stdout]
    end

    # The end-to-end one. Everything above asserts that the guard says
    # something; this asserts that saying it prevents the disclosure. Without
    # the guard this app precompiles component source into public/assets, and
    # SECRET_CONSTANT is readable in the output.
    def test_precompile_cannot_publish_component_source
      offend!
      result = precompile

      assert_equal 'raised', result[:status], result[:stdout]

      published = Dir.glob(File.join(@root, 'public/assets/**/*.{rb,erb}'))

      assert_empty published, 'no component source may reach public/assets'
    end

    # Reordering railties must not change the answer. This does not currently
    # discriminate between placements — an application's own initializers run
    # ahead of every engine's either way — but it pins the property the guard
    # actually depends on, which is that it observes a fully configured app.
    def test_the_verdict_does_not_depend_on_railtie_order
      offend!
      @railties_order = '[:main_app, :all]'

      result = boot('production')

      assert_equal 'raised', result[:status],
                   'the guard must not depend on where engines sit in the boot order'
    end

    private

    def seed_app
      components = File.join(@root, 'app/components/senren')
      FileUtils.mkdir_p(components)
      FileUtils.mkdir_p(File.join(@root, 'app/assets/stylesheets'))
      FileUtils.mkdir_p(File.join(@root, 'config/initializers'))
      FileUtils.mkdir_p(File.join(@root, 'public'))
      File.write(File.join(components, 'button_component.rb'),
                 "class ButtonComponent\n  SECRET_CONSTANT = 'do-not-publish'\nend\n")
      File.write(File.join(components, 'button_component.html.erb'), "<button></button>\n")
      File.write(File.join(@root, 'app/assets/stylesheets/app.css'), "body{}\n")
    end

    def offend!
      File.write(File.join(@root, 'config/initializers/assets.rb'), OFFENDING_INITIALIZER)
    end

    def precompile
      run_script('production', app_definition + <<~RUBY)
        require "rake"
        begin
          GuardBootProbe::Application.initialize!
          GuardBootProbe::Application.load_tasks
          Rake::Task["assets:precompile"].invoke
          puts "STATUS: precompiled"
        rescue RuntimeError => e
          puts "STATUS: raised"
          puts e.message
        end
      RUBY
    end

    def boot(env)
      run_script(env, boot_script)
    end

    def run_script(env, body)
      script = File.join(@root, 'boot.rb')
      File.write(script, body)
      stdout, stderr, = Open3.capture3(
        { 'RAILS_ENV' => env, 'SECRET_KEY_BASE_DUMMY' => '1' },
        RbConfig.ruby, '-I', lib_dir, script,
        chdir: @root
      )
      { status: stdout[/^STATUS: (\w+)/, 1], stdout: stdout, stderr: stderr }
    end

    def lib_dir
      File.expand_path('../../lib', __dir__)
    end

    def boot_script
      app_definition + <<~RUBY
        begin
          GuardBootProbe::Application.initialize!
          puts "STATUS: booted"
        rescue RuntimeError => e
          puts "STATUS: raised"
          puts e.message
        end
      RUBY
    end

    # ROOT is a constant, not a local: a `class Application` body opens a new
    # scope, and `config.root = root` there silently resolves to
    # Rails::Engine.root instead of raising.
    def app_definition
      <<~RUBY
        ROOT = #{@root.inspect}
        require "rails"
        require "action_controller/railtie"
        require "action_view/railtie"
        require "propshaft"
        require "senren/rails/engine"

        module GuardBootProbe
          class Application < ::Rails::Application
            config.root = ROOT
            config.load_defaults 7.1
            config.eager_load = false
            config.hosts.clear
            config.secret_key_base = "guard-boot-probe-secret"
            #{"config.railties_order = #{@railties_order}" if @railties_order}
          end
        end

      RUBY
    end
  end
end
