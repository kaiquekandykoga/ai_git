# frozen_string_literal: true
# lib/ai_git/commands/config.rb
#
# @purpose      Implement the `config` subcommand: print the resolved provider
#               settings so the user can see what the tool will talk to.
# @exports      AIGit::Commands::Config: .call.
# @dependencies ai_git/config: supplies every value printed;
#               ai_git/ai_client: supplies the read timeout shown;
#               ai_git/ui: formats the heading and the key/value lines.
# @sideEffects  Writes the resolved configuration to stdout.

require_relative "../ai_client"
require_relative "../config"
require_relative "../ui"

module AIGit
  module Commands
    module Config
      module_function

      def call(_argv = [])
        cfg = AIGit::Config

        AIGit::UI.heading("ai_git configuration")
        AIGit::UI.kv("Provider", cfg.provider)
        AIGit::UI.kv("Model", cfg.model_name)
        AIGit::UI.kv("Base URL", cfg.base_url)
        AIGit::UI.kv("Endpoint", cfg.endpoint)
        AIGit::UI.kv("Read timeout", "#{AIGit::AIClient::READ_TIMEOUT_SECONDS}s")
      end
    end
  end
end
