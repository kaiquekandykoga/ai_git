# frozen_string_literal: true

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

    def generate_commit_message(diff, model_name)
      raise 'No staged changes to generate commit message for' if diff.to_s.strip.empty?

      prompt = <<~PROMPT
        You are an expert Git commit message writer. Output ONLY the commit message — no explanations, no markdown, no backticks, no preamble.

        Here are the changes:
        #{diff}

        STRICT OUTPUT FORMAT (follow exactly):

        <short imperative title, max 72 chars>

        <blank line>

        ## Summary
        <2–4 bullet points covering the most important changes. Each bullet starts with a verb.>

        ## Why
        <1–3 sentences explaining the motivation or context behind the change. Omit if the reason is obvious.>

        RULES:
        - Title line: short, specific, imperative mood (e.g. "Add JWT login with refresh token support"). Avoid vague titles like "Update stuff" or "Fix bug".
        - Summary bullets: describe WHAT changed, not HOW the code looks. Focus on behaviour and impact.
        - Why section: explain the problem being solved or the goal being achieved. Skip if it adds no value.
        - No filler phrases ("this commit", "this PR", "as per discussion").
        - No line should exceed 72 characters.

        EXAMPLES OF GOOD OUTPUT:

        Add JWT-based login with refresh token support

        ## Summary
        - Implement login endpoint with access and refresh token issuance
        - Add token refresh route with rotation and expiry validation
        - Protect private routes via middleware that verifies access tokens
        - Store refresh tokens using encrypted HTTP-only cookies

        ## Why
        Users were being logged out on every page reload. Refresh tokens allow
        sessions to persist securely without requiring re-authentication.

        ---

        Prevent nil crash when user preferences are missing

        ## Summary
        - Add nil guard in ReportGenerator#process before accessing preferences
        - Fall back to system defaults when preferences object is absent

        ## Why
        Reports were raising NoMethodError in production for users created
        before the preferences feature shipped.

        ---

        Now generate the commit message:
      PROMPT

      json_body = {
        model: model_name,
        prompt: prompt,
        stream: false,
        # These parameters help a lot with strictness:
        temperature: 0.3,
        top_p: 0.9,
        stop: ["\n\n\n", '```', 'Here is', 'The commit message'],
        num_predict: 400 # Limit output length
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
        message = 'chore: update code' # fallback
      end

      message
    end
  end
end
