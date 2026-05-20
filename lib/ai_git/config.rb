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
      },
      "claude" => {
        default_model: "claude-opus-4-7",
        base_url: "https://api.anthropic.com",
        endpoint: "/v1/messages",
        request_format: :anthropic
      },
      "grok" => {
        default_model: "grok-4",
        base_url: "https://api.x.ai",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "llama_cpp" => {
        default_model: "default",
        base_url: "http://127.0.0.1:8080",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "unsloth" => {
        default_model: "unsloth/gemma-3-4b-it",
        base_url: "http://127.0.0.1:8000",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "mlx" => {
        default_model: "mlx-community/Llama-3.2-3B-Instruct-4bit",
        base_url: "http://127.0.0.1:8080",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "azure" => {
        default_model: "gpt-4o-mini",
        base_url: "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT",
        endpoint: "/chat/completions?api-version=2024-10-21",
        request_format: :azure
      },
      "openrouter" => {
        default_model: "openai/gpt-4o-mini",
        base_url: "https://openrouter.ai/api",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "mistral" => {
        default_model: "mistral-large-latest",
        base_url: "https://api.mistral.ai",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "gemini" => {
        default_model: "gemini-2.0-flash",
        base_url: "https://generativelanguage.googleapis.com",
        endpoint: "/v1beta/openai/chat/completions",
        request_format: :openai
      },
      "hugging_face" => {
        default_model: "meta-llama/Llama-3.3-70B-Instruct",
        base_url: "https://router.huggingface.co",
        endpoint: "/v1/chat/completions",
        request_format: :openai
      },
      "nvidia_nim" => {
        default_model: "meta/llama-3.3-70b-instruct",
        base_url: "https://integrate.api.nvidia.com",
        endpoint: "/v1/chat/completions",
        request_format: :openai
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
