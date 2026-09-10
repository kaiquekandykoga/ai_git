# frozen_string_literal: true
# lib/ai_git.rb
#
# @purpose      Library entry point and CLI router: load every component, then
#               dispatch the argument vector to the named subcommand.
# @exports      AIGit: SUBCOMMANDS, HELP_FLAGS, VERSION_FLAGS, .start.
# @dependencies ai_git/version, ai_git/config, ai_git/ui, ai_git/ai_client,
#               ai_git/git: the components the subcommands build on;
#               ai_git/commands/commit, ai_git/commands/config,
#               ai_git/commands/help: the subcommands .start dispatches to.
# @sideEffects  Prints the usage, the version or a hint to stdout; warns and
#               exits 1 on an unknown subcommand or option; .start runs the
#               selected subcommand.
# @notes        Every action needs its subcommand named: an empty vector
#               prints where to look and changes nothing, so a bare `ai_git`
#               can no longer commit by accident.

require_relative "ai_git/version"
require_relative "ai_git/config"
require_relative "ai_git/ui"
require_relative "ai_git/ai_client"
require_relative "ai_git/git"
require_relative "ai_git/commands/commit"
require_relative "ai_git/commands/config"
require_relative "ai_git/commands/help"

module AIGit
  module_function

  SUBCOMMANDS = {
    "commit" => AIGit::Commands::Commit,
    "config" => AIGit::Commands::Config,
    "help" => AIGit::Commands::Help
  }.freeze

  HELP_FLAGS    = %w[-h --help].freeze
  VERSION_FLAGS = %w[-v --version].freeze

  def start(args)
    args = args.dup
    first = args.first

    return puts(AIGit::Commands::Help::NO_SUBCOMMAND) if first.nil?
    return AIGit::Commands::Help.call([]) if HELP_FLAGS.include?(first)
    return puts(VERSION) if VERSION_FLAGS.include?(first)

    unknown_argument!(first) unless SUBCOMMANDS.key?(first)

    SUBCOMMANDS[args.shift].call(args)
  end

  def unknown_argument!(argument)
    label = argument.start_with?("-") ? "option" : "subcommand"
    warn "Unknown #{label}: #{argument}"
    warn AIGit::Commands::Help::USAGE
    exit 1
  end
end
