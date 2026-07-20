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

    # Sends `prompt` to the local llama.cpp server and returns the cleaned text body.
    def complete(prompt:, model_name:, temperature:)
      sanitize(openai_complete(prompt, model_name, temperature))
    end

    def openai_complete(prompt, model_name, temperature)
      body = {
        model: model_name,
        messages: [{ role: "user", content: prompt }],
        stream: false,
        temperature: temperature
      }

      data = post_json(body)
      data.dig("choices", 0, "message", "content").to_s
    end

    def transient_status?(code)
      TRANSIENT_STATUSES.include?(code.to_i)
    end

    def retry_delay(attempt)
      RETRY_BASE_DELAY * (2**(attempt - 1))
    end

    def post_json(body)
      uri = URI("#{AIGit::Config.base_url}#{AIGit::Config.endpoint}")
      attempt = 0

      loop do
        attempt += 1

        begin
          response = perform_request(uri, body)
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

    def perform_request(uri, body)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
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

      hint = response.code.to_i == 404 ? " Check the model name and base URL (see `ai_git config`)." : ""

      "#{provider} returned HTTP #{response.code} at #{uri}.#{hint}" \
        "#{body.empty? ? '' : "\n#{body}"}"
    end

    def connection_error_message(error)
      provider = AIGit::Config.provider
      base_url = AIGit::Config.base_url
      hint = "Is the local server running? See `ai_git config`."

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
