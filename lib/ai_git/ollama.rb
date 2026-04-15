require 'net/http'
require 'uri'
require 'json'

module AIGit
  module Ollama
    module_function

    def escape_json(string)
      string.gsub('\\', '\\\\')
            .gsub('"', '\\"')
            .gsub("\n", '\\n')
            .gsub("\r", '\\r')
            .gsub("\t", '\\t')
    end

    def generate_commit_message(diff)
      raise 'No staged changes to generate commit message for' if diff.to_s.strip.empty?

      prompt = 'Generate a commit message for these changes. ' \
               'First line: short commit title (under 72 chars). ' \
               'Second line: empty. ' \
               'Third line+: commit message body. ' \
               'Last line: AI-generated commit message by:\nhttps://github.com/kaiquekandykoga/ai_git ' \
               'Output only the commit message, no explanations.'

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
                       .gsub('\\"', '"')

      message = message.chomp if message.end_with?('"')

      message
    end
  end
end
