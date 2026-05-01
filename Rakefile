# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/system/**/*_test.rb')
  t.warning = false
end

namespace :test do
  Rake::TestTask.new(:system) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/system/**/*_test.rb']
    t.warning = false
  end
end

task default: :test
