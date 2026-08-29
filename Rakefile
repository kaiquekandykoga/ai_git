# frozen_string_literal: true
# Rakefile
#
# @purpose      Define the project's rake tasks: the test run and, when RuboCop
#               is installed, the lint task.
# @exports      Rake tasks: test (the default target), rubocop.
# @dependencies rake/testtask: builds the test task over test/**/test_*.rb;
#               rubocop/rake_task: optional, skipped when the gem is absent.
# @sideEffects  Defines global rake tasks; running them spawns ruby and rubocop
#               subprocesses.
# @notes        The rubocop require is rescued so the Rakefile still loads in an
#               environment without the development gems installed.

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
