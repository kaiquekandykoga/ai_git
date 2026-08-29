# frozen_string_literal: true
# Rakefile
#
# @purpose      Define the project's rake tasks: the test run, the gem
#               packaging and release tasks, and, when RuboCop is installed,
#               the lint task.
# @exports      Rake tasks: test (the default target), rubocop, and the
#               bundler-supplied build, install, and release.
# @dependencies rake/testtask: builds the test task over test/**/test_*.rb;
#               bundler/gem_tasks: supplies build/install/release from the
#               gemspec, used by the release workflow;
#               rubocop/rake_task: optional, skipped when the gem is absent.
# @sideEffects  Defines global rake tasks; running them spawns ruby, rubocop,
#               git, and gem subprocesses, and release pushes to RubyGems.
# @notes        The rubocop require is rescued so the Rakefile still loads in an
#               environment without the development gems installed.

require "bundler/gem_tasks"
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
