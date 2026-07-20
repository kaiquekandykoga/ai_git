# frozen_string_literal: true

require_relative "../ai_client"
require_relative "../config"
require_relative "../git"
require_relative "../ui"

module AIGit
  module Commands
    module Default
      module_function

      def generate_commit_message(diff, model_name, temperature: 0.3)
        raise "No staged changes to generate commit message for" if diff.to_s.strip.empty?

        message = AIClient.complete(
          prompt: build_prompt(diff),
          model_name: model_name,
          temperature: temperature
        )

        message = normalize_message(message)
        message.empty? ? "chore: update code" : message
      end

      # Keep the commit body readable: collapse runs of blank lines to a single
      # one and guarantee a blank line after the title so git sees a proper
      # subject/body split (otherwise `git log --oneline` mashes them together).
      def normalize_message(message)
        text = message.to_s.gsub(/\n{3,}/, "\n\n").strip
        lines = text.lines.map(&:chomp)
        return text if lines.length < 2

        lines.insert(1, "") unless lines[1].empty?
        lines.join("\n").gsub(/\n{3,}/, "\n\n").strip
      end

      def call(_argv = [])
        provider = AIGit::Config.provider
        model_name = AIGit::Config.model_name

        staged = AIGit::Git.staged_files
        abort "Error: No staged files. Use `git add` first." if staged.to_s.strip.empty?

        diff = AIGit::Git.diff
        branch = AIGit::Git.current_branch

        print_header(provider, model_name, staged, branch)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        AIGit::UI.info(AIGit::UI.bold("Generating commit message…"))
        message = generate_commit_message(diff, model_name)
        print_message(message)

        AIGit::Git.commit_with_message(message)
        AIGit::UI.success("Committed.")

        AIGit::Git.push_current_branch
        AIGit::UI.success("Pushed to origin/#{branch}.")

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        AIGit::UI.kv("Done in", format("%.1fs", elapsed))
      end

      def print_header(provider, model_name, staged, branch)
        AIGit::UI.kv("AI Provider", provider)
        AIGit::UI.kv("Model", model_name)
        AIGit::UI.kv("Staged Files", staged.to_s.strip.gsub("\n", ", "))
        AIGit::UI.kv("Branch", branch)
        puts
      end

      def print_message(message)
        puts
        puts AIGit::UI.bold("Commit message:")
        puts
        puts message
        puts
      end

      def build_prompt(diff)
        standard_prompt(diff)
      end

      def standard_prompt(diff)
        <<~PROMPT
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
      end
    end
  end
end
