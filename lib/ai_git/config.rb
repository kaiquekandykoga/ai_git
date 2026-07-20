# frozen_string_literal: true

module AIGit
  module Config
    PROVIDER = "llama_cpp"
    DEFAULT_MODEL = "default"
    DEFAULT_BASE_URL = "http://127.0.0.1:8080"
    ENDPOINT = "/v1/chat/completions"

    module_function

    def provider
      PROVIDER
    end

    def model_name
      ENV["AI_GIT_MODEL_NAME"] || DEFAULT_MODEL
    end

    def base_url
      ENV["AI_GIT_BASE_URL"] || DEFAULT_BASE_URL
    end

    def endpoint
      ENDPOINT
    end
  end
end
