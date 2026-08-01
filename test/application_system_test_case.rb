# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative 'dummy/config/environment'
require 'rails/test_help'
require 'capybara/rails'
require 'selenium/webdriver'
require_relative 'support/browser_performance_assertions'

SENREN_CHROME_CANDIDATES = [
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
  '/snap/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium'
].freeze

# An explicit path wins; otherwise use one only if it exists. Falling through to
# nil hands the job to Selenium Manager, which resolves (and downloads) a
# matching driver. Hard-coding /usr/bin/chromedriver made the suite unrunnable
# anywhere that is not a Linux CI image.
def senren_chrome_binary
  explicit = ENV.fetch('SENREN_CHROME_BIN', nil)
  return explicit if explicit && !explicit.empty?

  SENREN_CHROME_CANDIDATES.find { |path| File.executable?(path) }
end

def senren_chromedriver
  explicit = ENV.fetch('SENREN_CHROMEDRIVER', nil)
  return explicit if explicit && !explicit.empty?

  '/usr/bin/chromedriver' if File.executable?('/usr/bin/chromedriver')
end

Capybara.register_driver :senren_headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  chrome_path = senren_chrome_binary
  options.binary = chrome_path if chrome_path
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1000')

  driver_path = senren_chromedriver
  kwargs = { browser: :chrome, options: options }
  kwargs[:service] = Selenium::WebDriver::Chrome::Service.new(path: driver_path) if driver_path

  Capybara::Selenium::Driver.new(app, **kwargs).tap do |driver|
    driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(1400, 1000)
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include BrowserPerformanceAssertions

  driven_by :senren_headless_chrome
end
