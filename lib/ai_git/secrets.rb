# frozen_string_literal: true

module AIGit
  module Secrets
    module_function

    RISKY_PATHS = {
      "an environment file" => %r{(\A|/)\.env(\.[^/]+)?\z},
      "an SSH private key" => %r{(\A|/)id_(rsa|dsa|ecdsa|ed25519)\z},
      "a private key file" => /\.(pem|key|p12|pfx|jks|keystore)\z/i,
      "a credentials file" => %r{(\A|/)(credentials|\.netrc|\.npmrc|\.pypirc|\.htpasswd)\z},
      "a secrets file" => %r{(\A|/)secrets?\.(ya?ml|json|toml)\z}i
    }.freeze

    RISKY_CONTENT = {
      "a private key block" => /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
      "an AWS access key id" => /\bAKIA[0-9A-Z]{16}\b/,
      "a GitHub token" => /\b(gh[posur]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,})\b/,
      "an OpenAI-style API key" => /\bsk-[A-Za-z0-9_-]{20,}\b/,
      "a Slack token" => /\bxox[abprs]-[A-Za-z0-9-]{10,}\b/,
      "a Google API key" => /\bAIza[0-9A-Za-z_-]{35}\b/
    }.freeze

    SUSPICIOUS_ASSIGNMENT = /
      \b(api[_-]?key|secret|password|passwd|token|access[_-]?key)\b
      \s*[:=]\s*["'][^"']{8,}["']
    /ix.freeze

    def scan(staged_files, diff)
      { blocking: blocking_findings(staged_files, diff), warnings: warning_findings(diff) }
    end

    def blocking_findings(staged_files, diff)
      paths = staged_files.to_s.lines.map(&:strip).reject(&:empty?)
      added = added_lines(diff)

      findings = paths.flat_map do |path|
        RISKY_PATHS.filter_map { |label, pattern| "#{path} looks like #{label}" if path.match?(pattern) }
      end

      findings + RISKY_CONTENT.filter_map do |label, pattern|
        "added lines contain what looks like #{label}" if added.match?(pattern)
      end
    end

    def warning_findings(diff)
      return [] unless added_lines(diff).match?(SUSPICIOUS_ASSIGNMENT)

      ["added lines assign a value to a key/secret/password/token name"]
    end

    def added_lines(diff)
      diff.to_s.lines.select { |line| line.start_with?("+") && !line.start_with?("+++") }.join
    end
  end
end
