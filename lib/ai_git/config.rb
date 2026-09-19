# frozen_string_literal: true

require "uri"
require "yaml"

module AIGit
  module Config
    PROVIDER = "llama_cpp"
    DEFAULT_MODEL = "ggml-org/gemma-4-E4B-it-GGUF:Q8_0"
    DEFAULT_BASE_URL = "http://127.0.0.1:8080"
    ENDPOINT = "/v1/chat/completions"
    # Only a loopback host keeps the diff on this machine, so every other host
    # counts as remote when refusing plain http.
    LOOPBACK_HOST = /\A(localhost|127(\.\d{1,3}){3}|::1|0:0:0:0:0:0:0:1)\z/i
    CONFIG_DIR_NAME = ".ai_git"
    CONFIG_FILENAMES = %w[config.yml config.yaml].freeze
    SETTING_KEYS = %w[model_name base_url no_color].freeze
    TRUTHY_VALUES = [true, "true", "yes", "on", "1"].freeze

    module_function

    def provider
      PROVIDER
    end

    def config_dir
      File.join(Dir.home, CONFIG_DIR_NAME)
    rescue ArgumentError
      nil
    end

    def config_path
      dir = config_dir
      return nil if dir.nil?

      CONFIG_FILENAMES.map { |name| File.join(dir, name) }.find { |path| File.file?(path) }
    end

    def settings
      @settings ||= load_settings
    end

    # The config file is read once per process; tests drop the memo.
    def reset!
      @settings = nil
    end

    def load_settings
      path = config_path
      return {} if path.nil?

      validate_settings(parse_file(path), path)
    end

    def parse_file(path)
      YAML.safe_load_file(path) || {}
    rescue Psych::SyntaxError => e
      raise "Invalid YAML in #{path}: #{e.message}"
    rescue SystemCallError => e
      raise "Cannot read #{path}: #{e.message}"
    end

    def validate_settings(data, path)
      raise "Invalid config in #{path}: expected a mapping of settings." unless data.is_a?(Hash)

      data = data.transform_keys(&:to_s)
      unknown = data.keys - SETTING_KEYS
      return data if unknown.empty?

      # Raise rather than ignore, so a typo never silently keeps the default.

      raise "Unknown setting#{"s" if unknown.length > 1} in #{path}: #{unknown.join(", ")}. " \
            "Known settings: #{SETTING_KEYS.join(", ")}."
    end

    def string_setting(key, default)
      value = settings[key]
      return default if value.nil?

      raise "Invalid #{key} in #{config_path}: expected a non-empty string." unless string_value?(value)

      value.strip
    end

    def string_value?(value)
      value.is_a?(String) && !value.strip.empty?
    end

    def model_name
      string_setting("model_name", DEFAULT_MODEL)
    end

    def base_url
      string_setting("base_url", DEFAULT_BASE_URL)
    end

    def no_color?
      value = settings["no_color"]
      value = value.downcase if value.is_a?(String)
      TRUTHY_VALUES.include?(value)
    end

    def endpoint
      ENDPOINT
    end

    def base_uri
      uri = URI.parse(base_url)
      raise invalid_base_url_error unless valid_uri?(uri)

      uri
    rescue URI::InvalidURIError
      raise invalid_base_url_error
    end

    def invalid_base_url_error
      "Invalid base_url #{base_url.inspect}: expected an http(s) URL. See `ai_git config`."
    end

    def valid_uri?(uri)
      %w[http https].include?(uri.scheme) && !uri.host.to_s.empty?
    end

    def loopback_base_url?
      # An IPv6 host arrives bracketed, as in http://[::1]:8080.
      base_uri.host.to_s.delete("[]").match?(LOOPBACK_HOST)
    end

    def insecure_remote_base_url?
      !loopback_base_url? && base_uri.scheme == "http"
    end
  end
end
