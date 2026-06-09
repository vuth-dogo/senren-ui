# frozen_string_literal: true

require 'test_helper'

class ServerSideSecurityTest < Minitest::Test
  RUBY_SCAN_ROOTS = %w[lib templates].freeze
  ERB_TEMPLATE_GLOBS = %w[
    templates/components/**/*.erb
    lib/generators/**/*.tt
  ].freeze

  UNSAFE_RUBY_PATTERNS = {
    /\bfind_by_sql\s*\(/ => 'find_by_sql',
    /\bconnection\.execute\s*\(/ => 'connection.execute',
    /\bArel\.sql\s*\(/ => 'Arel.sql',
    /\bwhere\s*\(\s*["'][^"']*#\{/ => 'interpolated where SQL',
    /\border\s*\(\s*params\[/ => 'params-driven order SQL'
  }.freeze

  UNSAFE_ERB_PATTERNS = {
    /\braw\s*\(/ => 'raw output',
    /\.html_safe\b/ => 'html_safe output',
    /\bsafe_concat\s*\(/ => 'safe_concat output'
  }.freeze

  def test_ruby_sources_do_not_use_direct_sql_escape_hatches
    assert_no_pattern_matches ruby_files, UNSAFE_RUBY_PATTERNS
  end

  def test_component_templates_do_not_opt_out_of_rails_escaping
    assert_no_pattern_matches erb_templates, UNSAFE_ERB_PATTERNS
  end

  def test_rich_text_initial_content_is_server_sanitized
    template = File.read('templates/components/rich_text_editor_lite/rich_text_editor_lite_component.html.erb')

    assert_includes template, 'sanitize(initial_content'
    assert_includes template, 'tags: %w[p br strong b em i a ul ol li h1 h2 h3]'
    assert_includes template, 'attributes: %w[href rel target data-align]'
  end

  private

  def ruby_files
    RUBY_SCAN_ROOTS.flat_map { |root| Dir[File.join(root, '**/*.rb')] }.sort
  end

  def erb_templates
    ERB_TEMPLATE_GLOBS.flat_map { |glob| Dir[glob] }.sort
  end

  def assert_no_pattern_matches(files, patterns)
    offenses = files.flat_map do |path|
      File.readlines(path).flat_map.with_index(1) do |line, line_number|
        patterns.filter_map do |pattern, label|
          "#{path}:#{line_number} uses #{label}" if line.match?(pattern)
        end
      end
    end

    assert_empty offenses, "Security guard violations:\n#{offenses.join("\n")}"
  end
end
