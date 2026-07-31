# frozen_string_literal: true

require 'test_helper'
require 'stringio'
require_relative '../scripts/performance_check'

class PerformanceCheckTest < Minitest::Test
  def test_passes_with_small_payloads_and_lazy_loading_guidance
    with_performance_fixture do |root|
      output = StringIO.new

      assert PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'PASS Stimulus controller payload'
      assert_includes output.string, 'PASS Importmap lazy-loading guidance'
    end
  end

  def test_fails_when_single_controller_exceeds_budget
    with_performance_fixture do |root|
      write_file(root, 'templates/controllers/large_controller.js', 'a' * 101)
      write_file(root, 'config/performance_budgets.yml', <<~YAML)
        controllers:
          total_bytes: 1000
          total_gzip_bytes: 1000
          file_bytes: 100
      YAML

      output = StringIO.new

      refute PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'FAIL Stimulus controller payload'
      assert_includes output.string, 'large_controller.js'
    end
  end

  def test_fails_on_runtime_heavy_controller_patterns
    with_performance_fixture do |root|
      write_file(root, 'templates/controllers/network_controller.js',
                 "export default class { connect() { fetch('/slow') } }\n")

      output = StringIO.new

      refute PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'FAIL Stimulus runtime boundaries'
      assert_includes output.string, 'uses fetch call'
    end
  end

  def test_fails_when_a_controller_schedules_a_timer_it_never_clears
    with_performance_fixture do |root|
      write_file(root, 'templates/controllers/leaky_controller.js', <<~JS)
        export default class {
          connect() { setTimeout(() => this.panelTarget.hidden = true, 200) }
        }
      JS

      output = StringIO.new

      refute PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'FAIL Stimulus timer cleanup'
      assert_includes output.string, 'leaky_controller.js'
    end
  end

  def test_accepts_a_timer_that_is_cleared_on_disconnect
    with_performance_fixture do |root|
      write_file(root, 'templates/controllers/tidy_controller.js', <<~JS)
        export default class {
          connect() { this._t = window.setTimeout(() => {}, 200) }
          disconnect() { clearTimeout(this._t) }
        }
      JS

      output = StringIO.new

      assert PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'PASS Stimulus timer cleanup'
    end
  end

  def test_fails_without_importmap_lazy_loading_guidance
    with_performance_fixture do |root|
      write_file(root, 'README.md', "# Docs\n")

      output = StringIO.new

      refute PerformanceCheck.new(root: root, io: output).call
      assert_includes output.string, 'FAIL Importmap lazy-loading guidance'
    end
  end

  private

  def with_performance_fixture
    Dir.mktmpdir do |root|
      write_file(root, 'README.md', "lazyLoadControllersFrom\npreload: false\n")
      write_file(root, 'templates/controllers/example_controller.js', "export default class {}\n")
      write_file(root, 'templates/components/example/example_component.rb', "class ExampleComponent\nend\n")
      write_file(root, 'templates/components/example/example_component.html.erb', "<div>Example</div>\n")

      yield root
    end
  end

  def write_file(root, path, content)
    full_path = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end
