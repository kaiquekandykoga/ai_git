# frozen_string_literal: true

require "optparse"

module AIGit
  # Parses command-line flags into an Options struct. Each subcommand exposes
  # only the flags that make sense for it (see `parse`).
  Options = Struct.new(
    :yes, :no_push, :dry_run, :amend, :conventional, :all,
    keyword_init: true
  )

  module OptionsParser
    module_function

    # Parse `argv` for `command` ("default", "review", or "config").
    # Mutates argv (consumes recognised flags). Exits the process on -h/--help
    # or on an invalid flag.
    def parse(argv, command: "default")
      opts = Options.new(
        yes: false, no_push: false, dry_run: false,
        amend: false, conventional: false, all: false
      )

      parser = build_parser(opts, command)

      begin
        parser.parse!(argv)
      rescue OptionParser::ParseError => e
        warn "ai_git: #{e.message}"
        warn parser.help
        exit 1
      end

      opts
    end

    def build_parser(opts, command)
      OptionParser.new do |o|
        o.banner = "Usage: ai_git #{command == 'default' ? '' : "#{command} "}[options]"

        if %w[default review].include?(command)
          o.on("-a", "--all", "Stage all changes (git add -A) before running") { opts.all = true }
        end

        if command == "default"
          o.on("-y", "--yes", "Skip confirmation; commit and push") { opts.yes = true }
          o.on("--[no-]push", "Push after committing (default: on)") { |v| opts.no_push = !v }
          o.on("--dry-run", "Print the message only; do not commit or push") { opts.dry_run = true }
          o.on("--amend", "Amend the last commit (disables auto-push)") { opts.amend = true }
          o.on("--conventional", "Use Conventional Commits format (feat:/fix:/...)") { opts.conventional = true }
        end

        o.on("-h", "--help", "Show this message") do
          puts o
          exit 0
        end
      end
    end
  end
end
