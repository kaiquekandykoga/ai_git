# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test-unit"
require "tmpdir"
require "ai_git"

# Blank the config directory so the suite never reads the developer's own settings.
AIGit::Config.define_singleton_method(:config_dir) { nil }

def with_stub(mod, name, replacement)
  original = mod.method(name)
  mod.define_singleton_method(name) { |*args, **kwargs, &block| replacement.call(*args, **kwargs, &block) }
  yield
ensure
  mod.define_singleton_method(name, original)
end

def with_settings(settings, &)
  with_stub(AIGit::Config, :settings, -> { settings }, &)
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
