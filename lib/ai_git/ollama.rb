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

      prompt = <<~PROMPT
    You are an expert Git commit message writer. Your only job is to output a commit message — nothing else.

    Here are the changes:
    #{diff}

    Rules you MUST follow exactly:
    - Output ONLY the commit message. No explanations, no quotes, no markdown, no "Here is the commit message", no backticks.
    - Use this exact structure:
      1. First line: Conventional commit type + short imperative title (max 72 chars, ideally < 50)
      2. Second line: blank
      3. Body (optional but recommended): Clear, concise explanation of WHAT changed and WHY.

    Examples of good output:
    feat: add user authentication flow

    Implemented JWT-based login with refresh tokens. Added protected routes middleware.

    fix: prevent null pointer on missing metadata

    Added nil check in ReportGenerator#process before accessing user preferences.

    Now generate the commit message:
      PROMPT

      json_body = {
        model: 'phi4:14b',
        prompt: prompt,
        stream: false,
        # These parameters help a lot with strictness:
        temperature: 0.3,
        top_p: 0.9,
        stop: ["\n\n\n", "```", "Here is", "The commit message"],
        num_predict: 400   # Limit output length
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
      message = data['response'].to_s.strip

      # Aggressive cleaning
      message = message.gsub(/^(Here is|The commit message is|```|json|markdown)/i, '')
        .gsub(/^>\s*/, '')
        .gsub(/\\n/, "\n")
        .strip

      # Remove common unwanted prefixes/suffixes
      lines = message.lines.map(&:strip)
      lines.reject! { |line| line.match?(/^(Here|Output|Generated|Based on|The changes)/i) }

      message = lines.join("\n").strip

      # Ensure it has at least a title
      if message.lines.count < 1 || message.strip.empty?
        message = "chore: update code"  # fallback
      end

      message
    end 
  end
end
