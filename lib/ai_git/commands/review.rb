# frozen_string_literal: true

require_relative "../ai_client"
require_relative "../config"
require_relative "../git"
require_relative "../options"
require_relative "../ui"

module AIGit
  module Commands
    module Review
      module_function

      STOP_TOKENS = ["\n\n\n", "```", "Here is", "The review"].freeze

      def generate_review(diff, model_name)
        raise "No staged changes to review" if diff.to_s.strip.empty?

        review = AIClient.complete(
          prompt: build_prompt(diff),
          model_name: model_name,
          temperature: 0.2,
          num_predict: 600,
          stop: STOP_TOKENS
        )

        review.empty? ? "No review generated." : review
      end

      def call(argv = [])
        opts = AIGit::OptionsParser.parse(argv, command: "review")

        provider = AIGit::Config.provider
        model_name = AIGit::Config.model_name

        AIGit::Git.stage_all if opts.all

        staged = AIGit::Git.staged_files
        abort "Error: No staged files. Use `git add` first (or run with --all)." if staged.to_s.strip.empty?

        diff = AIGit::Git.diff
        branch = AIGit::Git.current_branch

        AIGit::UI.kv("AI Provider", provider)
        AIGit::UI.kv("Model", model_name)
        AIGit::UI.kv("Staged Files", staged.strip.gsub("\n", ", "))
        AIGit::UI.kv("Branch", branch)
        puts

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        AIGit::UI.info(AIGit::UI.bold("Reviewing staged changes…"))
        review = generate_review(diff, model_name)

        puts
        puts AIGit::UI.bold("Code review:")
        puts
        puts review
        puts

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        AIGit::UI.kv("Done in", format("%.1fs", elapsed))
      end

      def build_prompt(diff)
        <<~PROMPT
          You are a senior software engineer conducting a thorough code review. Output ONLY the review — no explanations, no markdown preamble, no backticks, no preamble.

          Here are the staged changes:
          #{diff}

          STRICT OUTPUT FORMAT (follow exactly):

          ## Summary
          <2–5 bullet points describing what this change does at a high level. Each bullet starts with a verb.>

          ## Suggestions
          <For each issue or improvement, use this format:>

          **<File and location, e.g. "app/models/user.rb">**
          - <Concise description of the issue or suggestion. Start with a verb. Be specific.>
          - <Another suggestion for the same file, if applicable.>

          <Repeat the file block for each file with suggestions. Omit files that look clean.>

          ## Verdict
          <One of: ✅ Looks good | ⚠️ Minor issues | 🚨 Needs attention>
          <One sentence explaining the verdict.>

          RULES:
          - Summary: describe WHAT the change does, not HOW the code looks. Focus on behaviour and intent.
          - Suggestions: flag real issues — bugs, edge cases, security problems, missing error handling, naming confusion, performance concerns, missing tests. Do NOT invent problems. If a file is clean, omit it entirely.
          - Be direct and constructive. No filler like "great job" or "consider possibly maybe".
          - No line should exceed 72 characters.
          - If the diff is a minor or trivial change (e.g. version bump, typo fix), keep the review brief.

          EXAMPLES OF GOOD OUTPUT:

          ## Summary
          - Add password reset flow with tokenised email verification
          - Introduce PasswordResetMailer with expiry-aware token links
          - Add DB migration for reset_token and reset_token_expires_at columns

          ## Suggestions

          **app/models/user.rb**
          - Ensure reset_token is invalidated after successful use to
            prevent token reuse attacks.
          - Add an index on reset_token column for fast lookup queries.

          **app/controllers/passwords_controller.rb**
          - Handle the case where the token has expired with a user-facing
            error message rather than a silent redirect.

          ## Verdict
          ⚠️ Minor issues
          Core logic is solid but token invalidation and expiry feedback
          need addressing before merge.

          ---

          ## Summary
          - Fix nil guard in ReportGenerator when preferences are absent

          ## Suggestions

          ## Verdict
          ✅ Looks good
          Safe defensive fix with no side effects.

          ---

          Now review the staged changes:
        PROMPT
      end
    end
  end
end
