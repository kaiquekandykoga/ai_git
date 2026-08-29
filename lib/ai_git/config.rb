# frozen_string_literal: true
# lib/ai_git/config.rb
#
# @purpose      Resolve the model provider settings from defaults and the
#               environment, and judge whether the base URL is safe to send to.
# @exports      AIGit::Config: PROVIDER, DEFAULT_MODEL, DEFAULT_BASE_URL,
#               ENDPOINT, LOOPBACK_HOST, .provider, .model_name, .base_url,
#               .endpoint, .base_uri, .valid_uri?, .loopback_base_url?,
#               .insecure_remote_base_url?.
# @dependencies uri: parses and validates AI_GIT_BASE_URL.
# @sideEffects  Reads AI_GIT_MODEL_NAME and AI_GIT_BASE_URL from the
#               environment; .base_uri raises a string on a malformed URL.
# @notes        Only a loopback host keeps the diff on this machine, so every
#               other host counts as remote for the plain-http refusal.

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
