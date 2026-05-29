# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "config"

module AIGit
  module AIClient
    module_function

    READ_TIMEOUT_SECONDS = 120
    OPEN_TIMEOUT_SECONDS = 10

    # Transient failures worth retrying with backoff.
    MAX_ATTEMPTS      = 3
    RETRY_BASE_DELAY  = 0.5
    TRANSIENT_STATUSES = [408, 425, 429, 500, 502, 503, 504].freeze
    RETRYABLE_ERRORS = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE,
      Net::OpenTimeout, Net::ReadTimeout, SocketError, EOFError
    ].freeze

    OUTPUT_NOISE_PREFIXES = /^(Here|Output|Generated|Based on|The changes)/i.freeze
    OUTPUT_NOISE_HEADERS  = /^(Here is|The (commit message|review) is|```|json|markdown)/i.freeze

    # Sends `prompt` to the configured provider and returns the cleaned text body.
    #
    # `temperature` and `num_predict` are forwarded to ollama; openai-compatible
    # providers (Jan AI) ignore num_predict because the chat endpoint manages it.
    def complete(prompt:, model_name:, temperature:, num_predict:, stop:)
      response_text =
        case AIGit::Config.request_format
        when :ollama    then ollama_complete(prompt, model_name, temperature, num_predict, stop)
        when :openai    then openai_complete(prompt, model_name, temperature)
        when :azure     then azure_complete(prompt, model_name, temperature)
        when :anthropic then anthropic_complete(prompt, model_name, temperature, num_predict, stop)
        else raise "Unsupported request_format: #{AIGit::Config.request_format}"
        end

      sanitize(response_text)
    end

    def ollama_complete(prompt, model_name, temperature, num_predict, stop)
      body = {
        model: model_name,
        prompt: prompt,
        stream: false,
        temperature: temperature,
        top_p: 0.9,
        stop: stop,
        num_predict: num_predict
      }

      data = post_json(body)
      data["response"].to_s
    end

    def openai_complete(prompt, model_name, temperature)
      body = {
        model: model_name,
        messages: [{ role: "user", content: prompt }],
        stream: false,
        temperature: temperature
      }

      headers = {}
      api_key = AIGit::Config.api_key
      headers["Authorization"] = "Bearer #{api_key}" if api_key

      data = post_json(body, headers: headers)
      data.dig("choices", 0, "message", "content").to_s
    end

    def azure_complete(prompt, model_name, temperature)
      api_key = AIGit::Config.api_key
      raise "Azure provider requires AI_GIT_API_KEY (or AZURE_OPENAI_API_KEY)" unless api_key

      body = {
        model: model_name,
        messages: [{ role: "user", content: prompt }],
        stream: false,
        temperature: temperature
      }

      data = post_json(body, headers: { "api-key" => api_key })
      data.dig("choices", 0, "message", "content").to_s
    end

    def anthropic_complete(prompt, model_name, temperature, num_predict, stop)
      api_key = AIGit::Config.api_key
      raise "Anthropic provider requires AI_GIT_API_KEY (or ANTHROPIC_API_KEY)" unless api_key

      body = {
        model: model_name,
        max_tokens: num_predict || 1024,
        temperature: temperature,
        stop_sequences: Array(stop).compact,
        messages: [{ role: "user", content: prompt }]
      }
      body.delete(:stop_sequences) if body[:stop_sequences].empty?

      headers = {
        "x-api-key" => api_key,
        "anthropic-version" => "2023-06-01"
      }

      data = post_json(body, headers: headers)
      data.dig("content", 0, "text").to_s
    end

    def transient_status?(code)
      TRANSIENT_STATUSES.include?(code.to_i)
    end

    def retry_delay(attempt)
      RETRY_BASE_DELAY * (2**(attempt - 1))
    end

    def post_json(body, headers: {})
      uri = URI("#{AIGit::Config.base_url}#{AIGit::Config.endpoint}")
      attempt = 0

      loop do
        attempt += 1

        begin
          response = perform_request(uri, body, headers)
        rescue *RETRYABLE_ERRORS => e
          raise connection_error_message(e) if attempt >= MAX_ATTEMPTS

          sleep retry_delay(attempt)
          next
        end

        return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

        if transient_status?(response.code) && attempt < MAX_ATTEMPTS
          sleep retry_delay(attempt)
          next
        end

        raise http_error_message(uri, response)
      end
    end

    def perform_request(uri, body, headers)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request.body = body.to_json

      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT_SECONDS,
        read_timeout: READ_TIMEOUT_SECONDS
      ) { |http| http.request(request) }
    end

    def http_error_message(uri, response)
      provider = AIGit::Config.provider
      body = response.body.to_s.strip
      body = "#{body[0, 500]}…" if body.length > 500

      hint =
        case response.code.to_i
        when 401, 403 then " Check AI_GIT_API_KEY."
        when 404      then " Check the model name and base URL (see `ai_git config`)."
        else ""
        end

      "#{provider} returned HTTP #{response.code} at #{uri}.#{hint}" \
        "#{body.empty? ? '' : "\n#{body}"}"
    end

    def connection_error_message(error)
      provider = AIGit::Config.provider
      base_url = AIGit::Config.base_url
      hint =
        if AIGit::Config.api_key_required?
          "Check your network connection and base URL."
        else
          "Is the local server running? See `ai_git config`."
        end

      "Cannot reach #{provider} at #{base_url} after #{MAX_ATTEMPTS} attempts: #{error.message}. #{hint}"
    end

    def sanitize(text)
      cleaned = text.to_s
                    .gsub(OUTPUT_NOISE_HEADERS, "")
                    .gsub(/^>\s*/, "")
                    .gsub(/\\n/, "\n")
                    .strip

      cleaned.lines
             .map(&:strip)
             .reject { |line| line.match?(OUTPUT_NOISE_PREFIXES) }
             .join("\n")
             .strip
    end
  end
end
