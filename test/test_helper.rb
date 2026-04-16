# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "test-unit"
require "ai_git"
require "ai_git/git"
require "ai_git/version"

def freebsd?
  RbConfig::CONFIG["host_os"].downcase.include?("freebsd")
end
