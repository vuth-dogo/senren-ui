# frozen_string_literal: true

require 'yaml'
require 'timeout'
require 'uri'

module BrowserPerformanceAssertions
  BUDGETS_PATH = File.expand_path('../../config/performance_budgets.yml', __dir__)
  PERFORMANCE_BUDGETS = YAML.safe_load_file(BUDGETS_PATH, aliases: false).freeze

  def performance_budget(section, key)
    PERFORMANCE_BUDGETS.fetch(section.to_s).fetch(key.to_s)
  end

  def loaded_senren_controllers
    page.evaluate_script('window.SenrenLoadedControllers || []')
  end

  def assert_loaded_senren_controllers(*expected)
    expected = expected.flatten.map(&:to_s).sort

    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until loaded_senren_controllers.sort == expected
    end
  rescue Timeout::Error
    assert_equal expected, loaded_senren_controllers.sort
  end

  def assert_dom_node_budget(key)
    count = page.evaluate_script('document.querySelectorAll("*").length')
    budget = performance_budget(:system, key)

    assert_operator count, :<=, budget, "Expected #{count} DOM nodes to be <= #{budget}"
  end

  def assert_no_external_ui_framework_resources
    resources = page.evaluate_script('performance.getEntriesByType("resource").map((entry) => entry.name)')
    forbidden = resources.select { |resource| external_ui_framework_resource?(resource) }

    assert_empty forbidden, "Unexpected external UI framework resources: #{forbidden.join(', ')}"
  end

  def install_performance_observers
    page.execute_script(<<~JS)
      window.__senrenPerf = { longTasks: [], layoutShifts: [], unsupported: [] }

      if ("PerformanceObserver" in window) {
        try {
          new PerformanceObserver((list) => {
            window.__senrenPerf.longTasks.push(...list.getEntries().map((entry) => entry.duration))
          }).observe({ type: "longtask" })
        } catch (error) {
          window.__senrenPerf.unsupported.push("longtask")
        }

        try {
          new PerformanceObserver((list) => {
            window.__senrenPerf.layoutShifts.push(...list.getEntries().map((entry) => entry.value))
          }).observe({ type: "layout-shift" })
        } catch (error) {
          window.__senrenPerf.unsupported.push("layout-shift")
        }
      }
    JS
  end

  def assert_no_long_tasks_over_budget
    budget = performance_budget(:system, :long_task_ms)
    long_tasks = page.evaluate_script('window.__senrenPerf?.longTasks || []')
    over_budget = long_tasks.select { |duration| duration > budget }

    assert_empty over_budget, "Expected no browser long tasks over #{budget}ms, got #{over_budget.inspect}"
  end

  def assert_interaction_budget(label, script)
    duration = page.evaluate_script(<<~JS)
      (() => {
        performance.mark("#{label}:start")
        #{script}
        performance.mark("#{label}:end")
        return performance.measure("#{label}", "#{label}:start", "#{label}:end").duration
      })()
    JS
    budget = performance_budget(:system, :interaction_ms)

    assert_operator duration, :<=, budget, "Expected #{label} to finish in <= #{budget}ms, got #{duration.round(2)}ms"
  end

  private

  def external_ui_framework_resource?(resource)
    uri = URI.parse(resource)
    host = uri.host.to_s.downcase
    path = uri.path.to_s.downcase

    return true if %w[cdn.jsdelivr.net unpkg.com ga.jspm.io].include?(host)

    path.match?(%r{/(react|vue|alpine|lit)([.@/-]|$)})
  rescue URI::InvalidURIError
    resource.match?(%r{/(react|vue|alpine|lit)([.@/-]|$)}i)
  end
end
