# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test-unit"
require "ai_git"

# Temporarily replace a module-level method (the client, git, the prompt) so
# tests can exercise command flow without a server or a real repo.
def with_stub(mod, name, replacement)
  original = mod.method(name)
  mod.define_singleton_method(name) { |*args, **kwargs, &block| replacement.call(*args, **kwargs, &block) }
  yield
ensure
  mod.define_singleton_method(name, original)
end

def with_env(values)
  original = values.keys.to_h { |key| [key, ENV[key]] }
  values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  yield
ensure
  original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
end
