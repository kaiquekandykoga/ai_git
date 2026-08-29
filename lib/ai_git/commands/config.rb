# frozen_string_literal: true
# lib/ai_git/commands/config.rb
#
# @purpose      Implement the `config` subcommand: print the resolved provider
#               settings and the file they come from, so the user can see what
#               the tool will talk to.
# @exports      AIGit::Commands::Config: .call, .resolved_rows, .config_file.
# @dependencies ai_git/config: supplies every value printed and the path of
#               the config file;
#               ai_git/ai_client: supplies the read timeout shown;
#               ai_git/ui: formats the heading and the key/value lines.
# @sideEffects  Writes the resolved configuration to stdout; raises a string
#               when the config file cannot be resolved.
# @notes        Every value is resolved before the first line is printed, so a
#               broken config file reports its error instead of a half-printed
#               listing.

require_relative "../ai_client"
require_relative "../config"
require_relative "../ui"

module AIGit
  module Commands
    module Config
      module_function

      def call(_argv = [])
        rows = resolved_rows(AIGit::Config)

        AIGit::UI.heading("ai_git configuration")
        rows.each { |key, value| AIGit::UI.kv(key, value) }
      end

      def resolved_rows(cfg)
        [
          ["Provider", cfg.provider],
          ["Model", cfg.model_name],
          ["Base URL", cfg.base_url],
          ["Endpoint", cfg.endpoint],
          ["Read timeout", "#{AIGit::AIClient::READ_TIMEOUT_SECONDS}s"],
          ["Config file", config_file(cfg)]
        ]
      end

      def config_file(cfg)
        return cfg.config_path if cfg.config_path

        dir = cfg.config_dir
        return "(no home directory)" if dir.nil?

        "#{File.join(dir, AIGit::Config::CONFIG_FILENAMES.first)} (not found)"
      end
    end
  end
end
