# frozen_string_literal: true
# Gemfile
#
# @purpose      Declare the development bundle: the gemspec's own dependencies
#               plus the tools used to build, test, and lint the gem.
# @dependencies ai_git.gemspec: pulled in by `gemspec` for runtime metadata;
#               rake: task runner; test-unit: test framework;
#               rubocop: linter, not required at load; benchmark: pinned so it
#               stays available as a bundled gem.
# @sideEffects  None.

source "https://rubygems.org"

gemspec

gem "benchmark"
gem "rake"
gem "rubocop", require: false
gem "test-unit"
