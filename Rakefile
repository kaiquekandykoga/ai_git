# frozen_string_literal: true

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
