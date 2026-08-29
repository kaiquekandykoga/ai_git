# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs = %w[lib test]
  t.test_files = Dir["test/**/test_*.rb"]
  t.verbose = true
  t.warning = false
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError # rubocop:disable Lint/SuppressedException
end

task default: :test
