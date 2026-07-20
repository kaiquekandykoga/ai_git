# frozen_string_literal: true

require_relative "../ai_client"
require_relative "../config"
require_relative "../ui"

module AIGit
  module Commands
    # `ai_git config` — print the resolved provider configuration so users can
    # see exactly which provider, model, URL and key will be used.
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
