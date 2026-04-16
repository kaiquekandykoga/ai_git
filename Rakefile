require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs = ["lib", "test"]
  t.test_files = Dir["test/**/test_*.rb"]
end

task default: :test