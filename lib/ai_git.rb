# frozen_string_literal: true

require_relative "ai_git/version"
require_relative "ai_git/config"
require_relative "ai_git/ui"
require_relative "ai_git/options"
require_relative "ai_git/ai_client"
require_relative "ai_git/git"
require_relative "ai_git/commands/review"
require_relative "ai_git/commands/default"
require_relative "ai_git/commands/config"

module AIGit
  module_function

  SUBCOMMANDS = {
    "review" => AIGit::Commands::Review,
    "config" => AIGit::Commands::Config,
    "default" => AIGit::Commands::Default
  }.freeze

  HELP_FLAGS    = %w[-h --help help].freeze
  VERSION_FLAGS = %w[-v --version].freeze

  USAGE = <<~USAGE
    Usage: ai_git [subcommand] [options]

    Subcommands:
      (none)    Generate a commit message, commit, and push staged files
      review    Review the staged files (experimental)
      config    Show the resolved provider configuration

    Options (default command):
      -y, --yes        Skip confirmation; commit and push
          --no-push    Commit but do not push
          --dry-run    Print the message only; do not commit or push
          --amend      Amend the last commit (disables auto-push)
          --conventional  Use Conventional Commits format (feat:/fix:/...)
      -a, --all        Stage all changes (git add -A) before running

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
