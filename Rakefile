# frozen_string_literal: true
# Rakefile
#
# @purpose      Define the project's rake tasks: the test run, the gem
#               packaging and release tasks, and, when RuboCop is installed,
#               the lint task.
# @exports      Rake tasks: default (lists the tasks, like rake -T), test,
#               rubocop, and the bundler-supplied build, install, and release.
# @dependencies rake/testtask: builds the test task over test/**/test_*.rb;
#               bundler/gem_tasks: supplies build/install/release from the
#               gemspec, used by the release workflow;
#               rubocop/rake_task: optional, skipped when the gem is absent.
# @sideEffects  Defines global rake tasks; running them spawns ruby, rubocop,
#               git, and gem subprocesses, and release pushes to RubyGems.
# @notes        The rubocop require is rescued so the Rakefile still loads in an
#               environment without the development gems installed; task
#               metadata recording is turned on so the default task can print
#               the task list the way rake -T does.

# Task comments are only recorded when rake is invoked with -T, so turn the
# recording on before the tasks are defined to let the default task list them.
Rake::TaskManager.record_task_metadata = true

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

desc "List the available tasks, like rake -T"
task :default do
  Rake.application.options.show_tasks = :tasks
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end
