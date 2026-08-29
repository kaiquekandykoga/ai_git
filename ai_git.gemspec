# frozen_string_literal: true
# ai_git.gemspec
#
# @purpose      Describe the ai_git gem for packaging: its metadata, the files
#               that ship, and the executable RubyGems installs.
# @exports      Gem::Specification for "ai_git": name, version, summary,
#               description, license, author, files, executables,
#               require_paths, requirements, homepage, metadata.
# @dependencies lib/ai_git/version: supplies AIGit::VERSION as the gem version.
# @sideEffects  None.
# @notes        `files` is an explicit Dir glob rather than a git listing, so a
#               new top-level path ships only once it is added here.

require_relative "lib/ai_git/version"

Gem::Specification.new do |spec|
  spec.name        = "ai_git"
  spec.version     = AIGit::VERSION
  spec.summary     = "AI-powered Git commit messages using a local LLM"
  spec.description = "Generate Git commit messages from staged changes via a local llama.cpp server, " \
                     "then commit and push."
  spec.license     = "BSD-3-Clause"
  spec.author      = "Kaíque Kandy Koga"

  spec.files = Dir["lib/**/*.rb", "bin/ai_git", "README.md", "LICENSE"]
  spec.executables = ["ai_git"]
  spec.require_paths = ["lib"]
  spec.requirements = []

  spec.homepage = "https://github.com/kaiquekandykoga/ai_git"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }
end
