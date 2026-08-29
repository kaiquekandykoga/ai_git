# frozen_string_literal: true
# test/test_helper.rb
#
# @purpose      Bootstrap every test run: put lib on the load path, load the
#               framework and the library, and define the shared helpers.
# @exports      with_stub, with_settings, with_config_dir: temporary
#               singleton-method, settings, and config-directory overrides,
#               restored when the block ends.
# @dependencies ai_git: the library under test;
#               test-unit: the framework every test file builds on;
#               tmpdir: backs the throwaway config directory.
# @sideEffects  Mutates $LOAD_PATH at load; with_stub redefines a singleton
#               method for the duration of the block; with_config_dir also
#               creates a temporary directory, writes a config file into it,
#               and drops the memoized settings.
# @notes        Every helper restores state in an ensure block, so a failing
#               assertion inside the block cannot leak into the next test.
#               Loading this file also blanks AIGit::Config.config_dir, so the
#               suite never reads the developer's own ~/.ai_git/config.yml.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test-unit"
require "tmpdir"
require "ai_git"

AIGit::Config.define_singleton_method(:config_dir) { nil }

def with_stub(mod, name, replacement)
  original = mod.method(name)
  mod.define_singleton_method(name) { |*args, **kwargs, &block| replacement.call(*args, **kwargs, &block) }
  yield
ensure
  mod.define_singleton_method(name, original)
end

def with_settings(settings, &block)
  with_stub(AIGit::Config, :settings, -> { settings }, &block)
end

def with_config_dir(contents, filename: "config.yml")
  Dir.mktmpdir do |dir|
    File.write(File.join(dir, filename), contents) unless contents.nil?
    with_stub(AIGit::Config, :config_dir, -> { dir }) do
      AIGit::Config.reset!
      yield dir
    end
  end
ensure
  AIGit::Config.reset!
end
