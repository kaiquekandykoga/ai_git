# frozen_string_literal: true
# lib/ai_git/ai_client.rb
#
# @purpose      Talk to the OpenAI-compatible chat endpoint: post the prompt,
#               retry transient failures, and strip the model's wrapping from
#               the reply.
# @exports      AIGit::AIClient: READ_TIMEOUT_SECONDS, OPEN_TIMEOUT_SECONDS,
#               MAX_ATTEMPTS, RETRY_BASE_DELAY, TRANSIENT_STATUSES,
#               RETRYABLE_ERRORS, .complete, .sanitize.
# @dependencies ai_git/config: supplies the base URL, endpoint, and provider
#               name used in requests and error messages;
#               json: encodes the request body and parses the response;
#               net/http, uri: perform the HTTP POST.
# @sideEffects  Makes network requests to the configured base URL; sleeps
#               between retries; raises a string message on failure.
# @notes        Retries with exponential backoff on the listed connection
#               errors and status codes only; any other status raises at once.
#               Sanitizing also unescapes a reply whose only newlines are
#               literal backslash-n, which some models emit.

require "json"
require "net/http"
require "uri"

require_relative "config"

module AIGit
  module AIClient
    module_function

    READ_TIMEOUT_SECONDS = 120
    OPEN_TIMEOUT_SECONDS = 10

    MAX_ATTEMPTS      = 3
    RETRY_BASE_DELAY  = 0.5
    TRANSIENT_STATUSES = [408, 425, 429, 500, 502, 503, 504].freeze
    RETRYABLE_ERRORS = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE,
      Net::OpenTimeout, Net::ReadTimeout, SocketError, EOFError
    ].freeze

    PREAMBLE_PREFIXES = /\A(here|output|generated|based\son|the\schanges|
                          the\s(commit\smessage|review)\sis|json|markdown)\b/ix.freeze
    CODE_FENCE = /\A`{3,}/.freeze
    ESCAPED_MESSAGE = /\A[^\n]*\\n\\n[^\n]*\z/.freeze

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
      lines = unescape_newlines(text.to_s)
              .lines
              .map { |line| line.rstrip.sub(/\A>\s*/, "") }

      strip_preamble(strip_code_fences(lines)).join("\n").strip
    end

    def unescape_newlines(text)
      return text unless text.match?(ESCAPED_MESSAGE)

      text.gsub(/\\n/, "\n")
    end

    def strip_code_fences(lines)
      lines = lines.drop_while { |line| line.strip.empty? }

      if lines.first&.match?(CODE_FENCE)
        unfenced = lines.first.sub(CODE_FENCE, "").strip
        unfenced.empty? ? lines.shift : lines[0] = unfenced
      end

      lines.pop while lines.last && (lines.last.strip.empty? || lines.last.strip.match?(CODE_FENCE))
      lines
    end

    def strip_preamble(lines)
      lines.drop_while { |line| line.strip.empty? || preamble?(line) }
    end

    def preamble?(line)
      line.strip.match?(PREAMBLE_PREFIXES)
    end
  end
end
