# frozen_string_literal: true
# ai_git.gemspec
#
# @purpose      Describe the ai_git gem for packaging: its metadata, the files
#               that ship, and the executable RubyGems installs.
# @exports      Gem::Specification for "ai_git": name, version, summary,
#               description, license, author, email, files, executables,
#               require_paths, requirements, required_ruby_version, homepage,
#               metadata.
# @dependencies lib/ai_git/version: supplies AIGit::VERSION as the gem version.
# @sideEffects  None.
# @notes        `files` is an explicit Dir glob rather than a git listing, so a
#               new top-level path ships only once it is added here.
#               `required_ruby_version` is the floor the CI matrix tests and
#               the RuboCop TargetRubyVersion; raise all three together.

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
