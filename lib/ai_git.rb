# frozen_string_literal: true

require_relative "ai_git/version"
require_relative "ai_git/config"
require_relative "ai_git/ui"
require_relative "ai_git/ai_client"
require_relative "ai_git/git"
require_relative "ai_git/commands/default"
require_relative "ai_git/commands/config"

module AIGit
  module_function

  SUBCOMMANDS = {
    "config" => AIGit::Commands::Config,
    "default" => AIGit::Commands::Default
  }.freeze

  HELP_FLAGS    = %w[-h --help help].freeze
  VERSION_FLAGS = %w[-v --version].freeze

  USAGE = <<~USAGE
    Usage: ai_git [subcommand]

    Subcommands:
      (none)    Generate a commit message, commit, and push staged files
      config    Show the resolved provider configuration

    Flags:
      -h, --help     Show this message
      -v, --version  Print version

    Environment variables:
      AI_GIT_MODEL_NAME    Override the default model
      AI_GIT_BASE_URL      Override the default base URL
      NO_COLOR             Disable colored output
  USAGE

  def start(args)
    args = args.dup
    first = args.first

    return puts(USAGE) if first && HELP_FLAGS.include?(first)
    return puts(VERSION) if first && VERSION_FLAGS.include?(first)

    command = "default"
    if first && !first.start_with?("-")
      unless SUBCOMMANDS.key?(first)
        warn "Unknown subcommand: #{first}"
        warn USAGE
        exit 1
      end
      command = args.shift
    end

    SUBCOMMANDS[command].call(args)
  end
end
