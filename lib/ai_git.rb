# frozen_string_literal: true

require_relative "ai_git/version"
require_relative "ai_git/config"
require_relative "ai_git/ai_client"
require_relative "ai_git/git"
require_relative "ai_git/commands/review"
require_relative "ai_git/commands/default"

module AIGit
  module_function

  SUBCOMMANDS = {
    "review" => AIGit::Commands::Review,
    "default" => AIGit::Commands::Default
  }.freeze

  HELP_FLAGS    = %w[-h --help help].freeze
  VERSION_FLAGS = %w[-v --version].freeze

  USAGE = <<~USAGE
    Usage: ai_git [subcommand]

    Subcommands:
      (none)    Generate commit message, commit, and push staged files
      review    Review the staged files (experimental)

    Flags:
      -h, --help     Show this message
      -v, --version  Print version

    Environment variables:
      AI_GIT_AI_PROVIDER   jan (default) | ollama
      AI_GIT_MODEL_NAME    Override provider's default model
      AI_GIT_BASE_URL      Override provider's default base URL
  USAGE

  def start(args)
    first = args.first

    return puts(USAGE) if first && HELP_FLAGS.include?(first)
    return puts(VERSION) if first && VERSION_FLAGS.include?(first)

    command = first || "default"

    unless SUBCOMMANDS.key?(command)
      warn "Unknown subcommand: #{command}"
      warn USAGE
      exit 1
    end

    SUBCOMMANDS[command].call
  end
end
