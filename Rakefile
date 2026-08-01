# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
                 .exclude('test/system/**/*_test.rb')
                 .exclude('test/integration/**/*_test.rb')
  t.warning = false
end

namespace :test do
  # Separate process, like system tests, and for the same reason: the unit
  # suite `load`s component classes directly, and booting the dummy app would
  # load them a second time. ViewComponent 4 raises RedefinedSlotError on the
  # duplicate declaration.
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/integration/**/*_test.rb']
    t.warning = false
  end

  Rake::TestTask.new(:system) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/system/**/*_test.rb']
    t.warning = false
  end
end

task default: :test
