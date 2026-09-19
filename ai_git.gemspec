# frozen_string_literal: true

require_relative "lib/ai_git/version"

Gem::Specification.new do |spec|
  spec.name        = "ai_git"
  spec.version     = AIGit::VERSION
  spec.summary     = "AI-powered Git commit messages using a local LLM"
  spec.description = "Generate Git commit messages from staged changes via a local llama.cpp server, " \
                     "then commit and push."
  spec.license     = "BSD-3-Clause"
  spec.author      = "Kaíque Kandy Koga"
  spec.email       = "kaiquekandykoga@gmail.com"

  spec.files = Dir["lib/**/*.rb", "bin/ai_git", "README.md", "CHANGELOG.md",
                   "doc/USAGE.md", "doc/RELEASE.md", "LICENSE"]
  spec.executables = ["ai_git"]
  spec.require_paths = ["lib"]
  spec.requirements = []
  # Raise together with the CI matrix and the RuboCop TargetRubyVersion.
  spec.required_ruby_version = ">= 3.1"

  spec.homepage = "https://github.com/kaiquekandykoga/ai_git"
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{spec.homepage}/tree/master",
    "documentation_uri" => "#{spec.homepage}/blob/master/doc/USAGE.md",
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }
end
