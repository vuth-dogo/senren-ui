# frozen_string_literal: true

require 'zlib'
require 'yaml'

class PerformanceCheck
  ROOT = File.expand_path('..', __dir__)

  DEFAULT_BUDGETS = {
    'controllers' => {
      'total_bytes' => 50_000,
      'total_gzip_bytes' => 14_000,
      'file_bytes' => 18_000
    },
    'components' => {
      'total_bytes' => 140_000,
      'file_bytes' => 8_000
    }
  }.freeze

  FORBIDDEN_CONTROLLER_PATTERNS = {
    /\bfetch\s*\(/ => 'fetch call',
    /\bXMLHttpRequest\b/ => 'XMLHttpRequest',
    /\bEventSource\b/ => 'EventSource',
    /\bWebSocket\b/ => 'WebSocket',
    /^\s*import\s+.*\b(?:react|vue|alpinejs|lit)\b/i => 'external UI framework import'
  }.freeze

  Result = Struct.new(:label, :ok, :details, keyword_init: true)

  def initialize(root: ROOT, config_path: nil, io: $stdout)
    @root = root
    @config_path = config_path || root_path('config/performance_budgets.yml')
    @budgets = load_budgets
    @io = io
  end

  def call
    results = [
      check_controller_payload,
      check_component_template_payload,
      check_controller_patterns,
      check_timer_cleanup,
      check_importmap_guidance
    ]

    print_results(results)
    results.all?(&:ok)
  end

  private

  attr_reader :budgets, :config_path, :io, :root

  def check_controller_payload
    files = controller_files
    total = files.sum { |path| File.size(path) }
    gzip_total = gzip_size(files.map { |path| File.binread(path) }.join("\n"))
    largest = files.max_by { |path| File.size(path) }
    largest_size = largest ? File.size(largest) : 0
    ok = total <= controller_budget('total_bytes') &&
         gzip_total <= controller_budget('total_gzip_bytes') &&
         largest_size <= controller_budget('file_bytes')

    Result.new(
      label: 'Stimulus controller payload',
      ok: ok,
      details: [
        "total=#{total}B budget=#{controller_budget('total_bytes')}B",
        "gzip=#{gzip_total}B budget=#{controller_budget('total_gzip_bytes')}B",
        "largest=#{relative(largest)} #{largest_size}B budget=#{controller_budget('file_bytes')}B"
      ]
    )
  end

  def check_component_template_payload
    files = component_files
    total = files.sum { |path| File.size(path) }
    largest = files.max_by { |path| File.size(path) }
    largest_size = largest ? File.size(largest) : 0
    ok = total <= component_budget('total_bytes') && largest_size <= component_budget('file_bytes')

    Result.new(
      label: 'Component template payload',
      ok: ok,
      details: [
        "total=#{total}B budget=#{component_budget('total_bytes')}B",
        "largest=#{relative(largest)} #{largest_size}B budget=#{component_budget('file_bytes')}B"
      ]
    )
  end

  def load_budgets
    return DEFAULT_BUDGETS unless File.exist?(config_path)

    DEFAULT_BUDGETS.merge(YAML.safe_load_file(config_path) || {}) do |_key, default, configured|
      default.merge(configured || {})
    end
  end

  def controller_budget(name)
    Integer(budgets.fetch('controllers').fetch(name))
  end

  def component_budget(name)
    Integer(budgets.fetch('components').fetch(name))
  end

  def check_controller_patterns
    offenses = controller_files.flat_map do |path|
      File.readlines(path).flat_map.with_index(1) do |line, line_number|
        FORBIDDEN_CONTROLLER_PATTERNS.filter_map do |pattern, label|
          "#{relative(path)}:#{line_number} uses #{label}" if line.match?(pattern)
        end
      end
    end

    Result.new(
      label: 'Stimulus runtime boundaries',
      ok: offenses.empty?,
      details: offenses.empty? ? ['no network calls or external UI framework imports'] : offenses
    )
  end

  # A timer that outlives its controller fires against a detached element. At
  # best that retains the subtree until it runs; at worst the callback touches a
  # Stimulus target that no longer exists and throws. Turbo navigations make
  # this routine rather than exotic, so it is a gate rather than a review note.
  def check_timer_cleanup
    offenses = controller_files.filter_map do |path|
      source = File.read(path)
      next unless source.match?(/\b(?:window\.)?set(?:Timeout|Interval)\s*\(/)
      next if source.include?('disconnect(') && source.match?(/clear(?:Timeout|Interval)\s*\(/)

      "#{relative(path)} schedules a timer that disconnect() never clears"
    end

    Result.new(
      label: 'Stimulus timer cleanup',
      ok: offenses.empty?,
      details: offenses.empty? ? ['every scheduled timer is cleared on disconnect'] : offenses
    )
  end

  def check_importmap_guidance
    readme = File.read(root_path('README.md'))
    ok = readme.include?('lazyLoadControllersFrom') && readme.include?('preload: false')

    Result.new(
      label: 'Importmap lazy-loading guidance',
      ok: ok,
      details: [ok ? 'README documents lazy controller loading' : lazy_loading_guidance_message]
    )
  end

  def lazy_loading_guidance_message
    'README must mention lazyLoadControllersFrom and preload: false'
  end

  def print_results(results)
    io.puts '==> Performance checks'
    results.each do |result|
      io.puts "#{result.ok ? 'PASS' : 'FAIL'} #{result.label}"
      result.details.each { |detail| io.puts "     #{detail}" }
    end
  end

  def controller_files
    Dir[root_path('templates/controllers/*.js')]
  end

  def component_files
    Dir[root_path('templates/components/**/*.{rb,erb}')]
  end

  def gzip_size(content)
    Zlib::Deflate.deflate(content).bytesize
  end

  def root_path(path)
    File.join(root, path)
  end

  def relative(path)
    path&.delete_prefix("#{root}/") || '(none)'
  end
end

exit(PerformanceCheck.new.call ? 0 : 1) if $PROGRAM_NAME == __FILE__
