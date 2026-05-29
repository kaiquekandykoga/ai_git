# frozen_string_literal: true

require_relative "../ai_client"
require_relative "../config"
require_relative "../git"
require_relative "../options"
require_relative "../ui"

module AIGit
  module Commands
    module Default
      module_function

      STOP_TOKENS = ["\n\n\n", "```", "Here is", "The commit message"].freeze

      def generate_commit_message(diff, model_name, conventional: false, temperature: 0.3)
        raise "No staged changes to generate commit message for" if diff.to_s.strip.empty?

        message = AIClient.complete(
          prompt: build_prompt(diff, conventional: conventional),
          model_name: model_name,
          temperature: temperature,
          num_predict: 400,
          stop: STOP_TOKENS
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

      def call(argv = [])
        opts = AIGit::OptionsParser.parse(argv, command: "default")

        provider = AIGit::Config.provider
        model_name = AIGit::Config.model_name

        AIGit::Git.stage_all if opts.all

        staged = AIGit::Git.staged_files
        if staged.to_s.strip.empty? && !opts.amend
          abort "Error: No staged files. Use `git add` first (or run with --all)."
        end

        diff = opts.amend ? AIGit::Git.amend_diff : AIGit::Git.diff
        branch = AIGit::Git.current_branch

        print_header(provider, model_name, staged, branch)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        AIGit::UI.info(AIGit::UI.bold("Generating commit message…"))
        message = generate_commit_message(diff, model_name, conventional: opts.conventional)
        print_message(message)

        if opts.dry_run
          AIGit::UI.info(AIGit::UI.dim("Dry run — nothing committed."))
          return
        end

        push_enabled = !opts.no_push && !opts.amend
        do_push = push_enabled

        if interactive?(opts)
          loop do
            case prompt_action(push_enabled)
            when :accept
              break
            when :commit_only
              do_push = false
              break
            when :edit
              message = AIGit::UI.edit_message(message)
              print_message(message)
            when :regenerate
              AIGit::UI.info(AIGit::UI.bold("Regenerating…"))
              message = generate_commit_message(diff, model_name, conventional: opts.conventional, temperature: 0.6)
              print_message(message)
            when :quit
              AIGit::UI.info("Aborted — nothing committed.")
              return
            end
          end
        end

        AIGit::Git.commit_with_message(message, amend: opts.amend)
        AIGit::UI.success(opts.amend ? "Amended last commit." : "Committed.")

        finish_push(do_push, opts, branch)

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        AIGit::UI.kv("Done in", format("%.1fs", elapsed))
      end

      def print_header(provider, model_name, staged, branch)
        files = staged.to_s.strip
        AIGit::UI.kv("AI Provider", provider)
        AIGit::UI.kv("Model", model_name)
        AIGit::UI.kv("Staged Files", files.empty? ? "(amending last commit)" : files.gsub("\n", ", "))
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

      def interactive?(opts)
        $stdin.tty? && $stdout.tty? && !opts.yes
      end

      def prompt_action(push_enabled)
        menu =
          if push_enabled
            "[a]ccept  [e]dit  [r]egenerate  [s]kip push  [q]uit"
          else
            "[a]ccept  [e]dit  [r]egenerate  [q]uit"
          end

        loop do
          case AIGit::UI.prompt("#{menu} (a): ").downcase
          when "", "a", "accept"     then return :accept
          when "e", "edit"           then return :edit
          when "r", "regenerate"     then return :regenerate
          when "s", "skip"           then return :commit_only if push_enabled
          when "q", "quit"           then return :quit
          else AIGit::UI.warn("Unrecognized option.")
          end
        end
      end

      def finish_push(do_push, opts, branch)
        if do_push
          AIGit::Git.push_current_branch
          AIGit::UI.success("Pushed to origin/#{branch}.")
        elsif opts.amend
          AIGit::UI.info(AIGit::UI.dim("Skipped push (amend). Push manually with: git push --force-with-lease"))
        else
          AIGit::UI.info(AIGit::UI.dim("Skipped push."))
        end
      end

      def build_prompt(diff, conventional: false)
        conventional ? conventional_prompt(diff) : standard_prompt(diff)
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

      def conventional_prompt(diff)
        <<~PROMPT
          You are an expert Git commit message writer who follows the Conventional Commits specification. Output ONLY the commit message — no explanations, no markdown fences, no preamble.

          Here are the changes:
          #{diff}

          STRICT OUTPUT FORMAT (follow exactly):

          <type>(<optional scope>): <short imperative summary, max 72 chars>

          <blank line>

          ## Summary
          <2–4 bullet points covering the most important changes. Each bullet starts with a verb.>

          ## Why
          <1–3 sentences explaining the motivation or context. Omit if obvious.>

          RULES:
          - type MUST be one of: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
          - Choose the type from the actual change: feat = new behaviour, fix = bug fix, refactor = no behaviour change, etc.
          - scope is optional; use a short lowercase noun for the affected area (e.g. auth, api, parser).
          - Append "!" after the type/scope for a breaking change (e.g. "feat(api)!: ...").
          - Subject line: imperative mood, no trailing period, max 72 chars.
          - Summary bullets describe WHAT changed and its impact, not HOW the code looks.
          - No filler phrases ("this commit", "this PR").
          - No line should exceed 72 characters.

          EXAMPLES OF GOOD OUTPUT:

          feat(auth): add JWT login with refresh token support

          ## Summary
          - Implement login endpoint issuing access and refresh tokens
          - Add token refresh route with rotation and expiry validation
          - Protect private routes via access-token middleware

          ## Why
          Users were logged out on every reload. Refresh tokens let sessions
          persist securely without re-authentication.

          ---

          fix(reports): prevent nil crash when preferences are missing

          ## Summary
          - Add nil guard in ReportGenerator#process before reading preferences
          - Fall back to system defaults when the preferences object is absent

          ## Why
          Reports raised NoMethodError for users created before preferences
          shipped.

          ---

          Now generate the commit message:
        PROMPT
      end
    end
  end
end
