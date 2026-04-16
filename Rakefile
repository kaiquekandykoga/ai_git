# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs = %w[lib test]
  t.test_files = Dir["test/**/test_*.rb"]
end

task default: :test
