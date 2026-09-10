# frozen_string_literal: true
# lib/ai_git/commands/help.rb
#
# @purpose      Implement the `help` subcommand and own every line of help
#               text: list what ai_git can do, or describe one subcommand.
# @exports      AIGit::Commands::Help: USAGE, NO_SUBCOMMAND, COMMIT_TOPIC,
#               CONFIG_TOPIC, HELP_TOPIC, TOPICS, ALIASES, .call, .topic.
# @sideEffects  Writes the usage or one topic to stdout; raises a string when
#               the named topic is unknown.
# @notes        The router, the bare invocation and a subcommand's own --help
#               all read from here, so the help a user sees has one source.

module AIGit
  module Commands
    module Help
      module_function

      USAGE = <<~USAGE
        Usage: ai_git <subcommand> [options]

        Subcommands:
          commit    Generate a commit message, commit, and push staged files
          config    Show the resolved provider configuration
          help      Describe a subcommand, or list them all

        Options:
          -h, --help     Show this message
          -v, --version  Print version

        Run `ai_git help <subcommand>` for what it does and which flags it
        takes, for example `ai_git help commit`.

        Configuration (~/.ai_git/config.yml, or config.yaml):
          model_name: ggml-org/gemma-4-E4B-it-GGUF:Q8_0   Model to prompt
          base_url: http://127.0.0.1:8080                 llama.cpp server
          no_color: true                                  Disable colored output

        Run `ai_git config` to see the resolved settings and the file they
        come from.
      USAGE

      NO_SUBCOMMAND = "Nothing to do: ai_git takes a subcommand. " \
                      "Run `ai_git help` to see what it can do."

      COMMIT_TOPIC = <<~TOPIC
        Usage: ai_git commit [options]

        Generate a commit message from the staged diff, then commit and push.

        ai_git reads the staged files and their diff, asks the configured
        llama.cpp server for a message, and prints what comes back: a short
        imperative title, a blank line, then prose explaining why the change
        was necessary rather than restating the diff.

        On a terminal it then asks what to do with that message:

          Commit this message? [A]ccept / [e]dit / [r]egenerate / [q]uit:

        Accepting commits and pushes to origin. Piped or scripted runs skip
        the question and commit unattended, as does --yes.

        Options:
          -n, --dry-run  Print the generated message and change nothing
              --no-push  Commit locally without pushing
          -y, --yes      Skip the confirmation prompt (unattended)
          -f, --force    Proceed despite secret or remote-server warnings
          -h, --help     Show this message

        Before the diff leaves the machine, ai_git refuses to send it
        unencrypted to a non-loopback host, and refuses to send likely
        secrets — .env files, private keys, AWS/GitHub/Slack-shaped tokens.
        Pass --force to override either refusal.

        Requires staged changes: run `git add` first.
      TOPIC

      CONFIG_TOPIC = <<~TOPIC
        Usage: ai_git config

        Show the resolved provider configuration: the provider, model name,
        base URL, endpoint and read timeout ai_git will use, and the path of
        the file those settings came from.

        Settings live in ~/.ai_git/config.yml (config.yaml is read too). The
        file is optional — without it every setting falls back to its
        default. An unknown key or a malformed value fails the run with an
        error naming the file.

        This subcommand takes no options and only reads: nothing is
        committed, pushed, or sent to the model server.
      TOPIC

      HELP_TOPIC = <<~TOPIC
        Usage: ai_git help [subcommand]

        With no argument, list every subcommand, the top-level options and
        the configuration file ai_git reads.

        Name a subcommand to see what it does and which flags it takes:

          ai_git help commit
          ai_git help config

        `ai_git -h` and `ai_git --help` print the same overview as a bare
        `ai_git help`, and every subcommand accepts --help for its own.
      TOPIC

      TOPICS = {
        "commit" => COMMIT_TOPIC,
        "config" => CONFIG_TOPIC,
        "help" => HELP_TOPIC
      }.freeze

      ALIASES = { "-h" => "help", "--help" => "help" }.freeze

      def call(argv = [])
        name = argv.to_a.first
        return puts(USAGE) if name.nil?

        puts(topic(name))
      end

      def topic(name)
        key = name.to_s
        TOPICS.fetch(ALIASES.fetch(key, key)) { raise unknown_topic_error(key) }
      end

      def unknown_topic_error(name)
        "Unknown help topic: #{name}. Known topics: #{TOPICS.keys.join(', ')}."
      end
    end
  end
end
