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
    Usage: ai_git [subcommand] [options]

    Subcommands:
      (none)    Generate a commit message, commit, and push staged files
      config    Show the resolved provider configuration

    Options:
      -n, --dry-run  Print the generated message and change nothing
          --no-push  Commit locally without pushing
      -y, --yes      Skip the confirmation prompt (unattended)
      -f, --force    Proceed despite secret or remote-server warnings
      -h, --help     Show this message
      -v, --version  Print version

    On a terminal ai_git asks before committing: accept, edit, regenerate or
    quit. Piped or scripted runs commit and push unattended.

    Environment variables:
      AI_GIT_MODEL_NAME    Override the default model
      AI_GIT_BASE_URL      Override the default base URL
      NO_COLOR             Disable colored output
      AI_GIT_NO_COLOR      Disable colored output
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
