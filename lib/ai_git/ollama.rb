require 'net/http'
require 'uri'
require 'json'

module AIGit
  module Ollama
    module_function

    def escape_json(string)
      string.gsub('\\', '\\\\')
            .gsub('"', '\"')
            .gsub("\n", '\\n')
            .gsub("\r", '\\r')
            .gsub("\t", '\\t')
    end

    def generate_commit_message(diff)
      raise 'No staged changes to generate commit message for' if diff.to_s.strip.empty?

      prompt = """You are an expert Git commit message writer.

Generate a commit message for the provided changes following this exact format:

1. First line: Short title (< 72 chars, preferably < 50), starting with a verb in imperative present tense.
2. Second line: Blank
3. Body (from line 3): Clear explanation of the changes and their rationale.

Use conventional commit types (feat/fix/refactor/chore/etc.) when appropriate.
Output nothing but the commit message itself. No quotes, no explanations, no markdown."""

      json_body = {
        model: 'llama3.2:3b',
        prompt: prompt,
        stream: false
      }.to_json

      uri = URI('http://localhost:11434/api/generate')
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = json_body

      response = Net::HTTP.start(uri.host, uri.port, read_timeout: 120) do |http|
        http.request(request)
      end

      raise 'Failed to connect to Ollama. Is it running?' unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      message = data['response'].to_s

      message = message.gsub('\\n', "\n")
                       .gsub('\"', '"')

      message = message.chomp if message.end_with?('"')

      message
    end
  end
end
