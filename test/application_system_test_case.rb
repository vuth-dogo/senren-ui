# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative 'dummy/config/environment'
require 'rails/test_help'
require 'capybara/rails'
require 'selenium/webdriver'
require_relative 'support/browser_performance_assertions'

Capybara.register_driver :senren_headless_chrome do |app|
  chrome_path = ENV['SENREN_CHROME_BIN'] ||
                [
                  '/usr/bin/chromium-browser',
                  '/usr/bin/chromium',
                  '/snap/bin/chromium'
                ].find { |path| File.executable?(path) }
  driver_path = ENV.fetch('SENREN_CHROMEDRIVER', '/usr/bin/chromedriver')

  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = chrome_path if chrome_path
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1000')

  service = Selenium::WebDriver::Chrome::Service.new(path: driver_path)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service).tap do |driver|
    driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(1400, 1000)
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include BrowserPerformanceAssertions

  driven_by :senren_headless_chrome
end
