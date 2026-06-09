# frozen_string_literal: true

require 'test_helper'

class JavaScriptControllerSecurityTest < Minitest::Test
  CONTROLLER_ROOT = File.expand_path('../../templates/controllers', __dir__)
  RICH_TEXT_CONTROLLER = File.join(CONTROLLER_ROOT, 'rich_text_editor_lite_controller.js')

  UNSAFE_DOM_SINKS = {
    /\.innerHTML\s*=/ => 'innerHTML assignment',
    /\.outerHTML\s*=/ => 'outerHTML assignment',
    /\.insertAdjacentHTML\s*\(/ => 'insertAdjacentHTML',
    /\bdocument\.write\s*\(/ => 'document.write',
    /\beval\s*\(/ => 'eval',
    /\bnew Function\s*\(/ => 'new Function'
  }.freeze

  def test_stimulus_controllers_do_not_write_unsanitized_html_or_eval_code
    offenses = controller_files.flat_map do |path|
      File.readlines(path).flat_map.with_index(1) do |line, line_number|
        UNSAFE_DOM_SINKS.filter_map do |pattern, label|
          "#{relative(path)}:#{line_number} uses #{label}" if line.match?(pattern)
        end
      end
    end

    assert_empty offenses, "Unsafe client-side sinks found:\n#{offenses.join("\n")}"
  end

  def test_inner_html_reads_are_confined_to_rich_text_controller
    files = controller_files.select { |path| File.read(path).include?('innerHTML') }

    assert_equal [RICH_TEXT_CONTROLLER], files
  end

  def test_window_open_uses_noopener_and_noreferrer
    offenses = controller_files.filter_map do |path|
      source = File.read(path)
      next unless source.include?('window.open(')

      relative(path) unless source.include?('noopener,noreferrer')
    end

    assert_empty offenses, "window.open must use noopener,noreferrer in: #{offenses.join(', ')}"
  end

  private

  def controller_files
    Dir[File.join(CONTROLLER_ROOT, '*.js')]
  end

  def relative(path)
    path.delete_prefix("#{Dir.pwd}/")
  end
end
