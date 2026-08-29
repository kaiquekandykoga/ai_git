# frozen_string_literal: true

require "uri"

module AIGit
  module Config
    PROVIDER = "llama_cpp"
    DEFAULT_MODEL = "ggml-org/gemma-4-E4B-it-GGUF:Q8_0"
    DEFAULT_BASE_URL = "http://127.0.0.1:8080"
    ENDPOINT = "/v1/chat/completions"
    LOOPBACK_HOST = /\A(localhost|127(\.\d{1,3}){3}|::1|0:0:0:0:0:0:0:1)\z/i.freeze

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

    def base_uri
      uri = URI.parse(base_url)
      raise "Invalid AI_GIT_BASE_URL #{base_url.inspect}: expected an http(s) URL." unless valid_uri?(uri)

      uri
    rescue URI::InvalidURIError
      raise "Invalid AI_GIT_BASE_URL #{base_url.inspect}: expected an http(s) URL."
    end

    def valid_uri?(uri)
      %w[http https].include?(uri.scheme) && !uri.host.to_s.empty?
    end

    def loopback_base_url?
      base_uri.host.to_s.delete("[]").match?(LOOPBACK_HOST)
    end

    def insecure_remote_base_url?
      !loopback_base_url? && base_uri.scheme == "http"
    end
  end
end
