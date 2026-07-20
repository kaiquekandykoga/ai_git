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

          <short imperative title, max 72 chars, summarizing the main change>

          <blank line>

          <body written as plain prose paragraphs, no headers, no bullet points, no tags.
          Explain why the change is necessary and what problem it solves, how it addresses
          the issue at a high level (do not recount line-by-line code changes, those are
          visible in the diff), and any side effects or tradeoffs reviewers should know about.>

          RULES:
          - Title line: short, specific, imperative mood (e.g. "Add JWT login with refresh token support"). Avoid vague titles like "Update stuff" or "Fix bug".
          - Body: plain prose only. No markdown headers, no bullet points, no bold/italics, no tags.
          - Body: explain WHY the change is necessary and WHAT problem it solves, then HOW it addresses the issue at a high level. Do not describe the code line by line.
          - Body: mention side effects or tradeoffs only if they exist and matter to a reviewer.
          - No filler phrases ("this commit", "this PR", "as per discussion").
          - No line should exceed 72 characters.

          EXAMPLES OF GOOD OUTPUT:

          Add JWT-based login with refresh token support

          Users were being logged out on every page reload because sessions
          were not persisted across requests. This made the app unusable for
          any workflow longer than a single page view.

          Introduces a login endpoint that issues short-lived access tokens
          alongside long-lived refresh tokens, plus a refresh route that
          rotates tokens on use. Refresh tokens are stored in encrypted
          HTTP-only cookies so the client never handles them directly.

          Adds a new middleware layer on private routes, so any route not
          yet wired to it remains unauthenticated until migrated.

          ---

          Prevent nil crash when user preferences are missing

          Reports were raising NoMethodError in production for accounts
          created before the preferences feature shipped, since those
          accounts have no preferences record at all.

          Falls back to system defaults whenever a user's preferences are
          absent, so report generation no longer assumes the record exists.

          ---

          Now generate the commit message:
        PROMPT
      end
    end
  end
end
