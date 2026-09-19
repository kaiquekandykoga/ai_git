# frozen_string_literal: true

require_relative "../ai_client"
require_relative "../config"
require_relative "../ui"
require_relative "help"

module AIGit
  module Commands
    module Config
      module_function

      def call(argv = [])
        argument = argv.to_a.first
        return puts(AIGit::Commands::Help.topic("config")) if AIGit::HELP_FLAGS.include?(argument)
        raise "Unknown option: #{argument}. Run `ai_git help config` for usage." unless argument.nil?

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
