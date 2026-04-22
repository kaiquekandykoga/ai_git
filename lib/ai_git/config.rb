# frozen_string_literal: true

module AIGit
  module Config
    PROVIDERS = {
      "jan" => {
        default_model: "Jan-v3.5-4B-Q4_K_XL",
        base_url: "http://127.0.0.1:1337",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "ollama" => {
        default_model: "gemma4:e4b",
        base_url: "http://localhost:11434",
        endpoint: "/api/generate",
        request_format: :ollama
      }
    }.freeze

    def self.provider
      ENV["AI_GIT_AI_PROVIDER"] || "jan"
    end

    def self.model_name
      ENV["AI_GIT_MODEL_NAME"] || PROVIDERS[provider][:default_model]
    end

    def self.base_url
      ENV["AI_GIT_BASE_URL"] || PROVIDERS[provider][:base_url]
    end

    def self.endpoint
      PROVIDERS[provider][:endpoint]
    end

    def self.request_format
      PROVIDERS[provider][:request_format]
    end

    def self.config
      PROVIDERS[provider]
    end
  end
end
