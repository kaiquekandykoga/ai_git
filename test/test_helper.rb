# frozen_string_literal: true
# test/test_helper.rb
#
# @purpose      Bootstrap every test run: put lib on the load path, load the
#               framework and the library, and define the shared helpers.
# @exports      with_stub, with_env: temporary singleton-method and environment
#               overrides, restored when the block ends.
# @dependencies ai_git: the library under test;
#               test-unit: the framework every test file builds on.
# @sideEffects  Mutates $LOAD_PATH at load; with_env mutates ENV and with_stub
#               redefines singleton methods for the duration of the block.
# @notes        Both helpers restore state in an ensure block, so a failing
#               assertion inside the block cannot leak into the next test.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test-unit"
require "ai_git"

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
