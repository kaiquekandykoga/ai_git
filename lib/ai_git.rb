# frozen_string_literal: true

require_relative "ai_git/version"
require_relative "ai_git/git"
require_relative "ai_git/ollama"
require_relative "ai_git/review"
require_relative "ai_git/default"

module AIGit
  module_function

  SUBCOMMANDS = {
    "review" => AIGit::Review,
    "default" => AIGit::Default
  }.freeze

  def start(args)
    command = args.first || "default"

    raise "Unknown subcommand: #{command}" unless SUBCOMMANDS.key?(command)

    SUBCOMMANDS[command].call
  end
end
