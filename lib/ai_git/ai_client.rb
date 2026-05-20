# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "config"

module AIGit
  module AIClient
    module_function

    READ_TIMEOUT_SECONDS = 120

    OUTPUT_NOISE_PREFIXES = /^(Here|Output|Generated|Based on|The changes)/i.freeze
    OUTPUT_NOISE_HEADERS  = /^(Here is|The (commit message|review) is|```|json|markdown)/i.freeze

    # Sends `prompt` to the configured provider and returns the cleaned text body.
    #
    # `temperature` and `num_predict` are forwarded to ollama; openai-compatible
    # providers (Jan AI) ignore num_predict because the chat endpoint manages it.
    def complete(prompt:, model_name:, temperature:, num_predict:, stop:)
      response_text =
        case AIGit::Config.request_format
        when :ollama then ollama_complete(prompt, model_name, temperature, num_predict, stop)
        when :openai then openai_complete(prompt, model_name, temperature)
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

      data = post_json(body)
      data.dig("choices", 0, "message", "content").to_s
    end

    def post_json(body)
      uri = URI("#{AIGit::Config.base_url}#{AIGit::Config.endpoint}")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = Net::HTTP.start(uri.host, uri.port, read_timeout: READ_TIMEOUT_SECONDS) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to connect to #{AIGit::Config.provider} at #{uri}. Is it running? (HTTP #{response.code})"
      end

      JSON.parse(response.body)
    rescue Errno::ECONNREFUSED => e
      raise "Cannot reach #{AIGit::Config.provider} at #{AIGit::Config.base_url}: #{e.message}"
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
