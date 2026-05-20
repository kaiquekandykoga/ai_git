# frozen_string_literal: true

module AIGit
  module Config
    DEFAULT_PROVIDER = "jan"

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

    module_function

    def provider
      name = ENV["AI_GIT_AI_PROVIDER"] || DEFAULT_PROVIDER

      unless PROVIDERS.key?(name)
        raise "Unknown AI_GIT_AI_PROVIDER=#{name.inspect}. Expected one of: #{PROVIDERS.keys.join(', ')}"
      end

      name
    end

    def model_name
      ENV["AI_GIT_MODEL_NAME"] || provider_config[:default_model]
    end

    def base_url
      ENV["AI_GIT_BASE_URL"] || provider_config[:base_url]
    end

    def endpoint
      provider_config[:endpoint]
    end

    def request_format
      provider_config[:request_format]
    end

    def provider_config
      PROVIDERS.fetch(provider)
    end
  end
end
