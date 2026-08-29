# frozen_string_literal: true
# lib/ai_git/commands/default.rb
#
# @purpose      Implement the default subcommand end to end: guard the staged
#               diff, generate a commit message, confirm it, then commit and
#               push.
# @exports      AIGit::Commands::Default: .call, .run, .generate_commit_message,
#               .normalize_message, .build_prompt.
# @dependencies ai_git/options: parses the flags .call receives;
#               ai_git/git: reads the staged tree, commits, and pushes;
#               ai_git/secrets: screens the diff before it leaves the machine;
#               ai_git/config: supplies the model name and base-URL checks;
#               ai_git/ai_client: generates the message;
#               ai_git/prompt: runs the interactive confirmation and editor;
#               ai_git/ui: prints the header, the message, and the outcome.
# @sideEffects  Reads the repository, commits, pushes to origin, makes network
#               requests, spawns the editor, and writes to stdout and stderr;
#               raises a string on any refusal.
# @notes        Refuses to send the diff over plain http to a non-loopback host
#               or to send likely secrets, unless --force is passed. The
#               confirmation prompt is skipped unless both streams are a tty.

require_relative "../ai_client"
require_relative "../config"
require_relative "../git"
require_relative "../options"
require_relative "../prompt"
require_relative "../secrets"
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
        raise empty_response_error if message.empty?

        message
      end

      def empty_response_error
        "#{AIGit::Config.provider} returned an empty commit message. " \
          "Check the model name and that the server is loaded (see `ai_git config`), then retry."
      end

      def normalize_message(message)
        text = message.to_s.gsub(/\n{3,}/, "\n\n").strip
        lines = text.lines.map(&:chomp)
        return text if lines.length < 2

        lines.insert(1, "") unless lines[1].empty?
        lines.join("\n").gsub(/\n{3,}/, "\n\n").strip
      end

      def call(argv = [])
        options = AIGit::Options.parse(argv)
        return puts(AIGit::USAGE) if options.help?

        staged = AIGit::Git.staged_files
        raise "No staged files. Use `git add` first." if staged.strip.empty?

        run(staged, options)
      end

      def run(staged, options)
        diff = AIGit::Git.diff
        branch = AIGit::Git.current_branch
        model_name = AIGit::Config.model_name

        check_base_url!(options)
        check_secrets!(staged, diff, options)

        print_header(AIGit::Config.provider, model_name, staged, branch)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        message = resolve_message(diff, model_name, options)
        return AIGit::UI.info("Aborted. Nothing committed.") if message.nil?

        return dry_run_summary(branch, options) if options.dry_run?

        commit_and_push(message, branch, options)
        AIGit::UI.kv("Done in", format("%.1fs", Process.clock_gettime(Process::CLOCK_MONOTONIC) - started))
      end

      def resolve_message(diff, model_name, options)
        loop do
          AIGit::UI.info(AIGit::UI.bold("Generating commit message…"))
          message = generate_commit_message(diff, model_name)
          print_message(message)

          return message unless confirm?(options)

          case AIGit::Prompt.ask_action
          when :accept then return message
          when :edit then return edited_message(message)
          when :abort then return nil
          end
        end
      end

      def confirm?(options)
        !options.dry_run? && !options.assume_yes? && AIGit::Prompt.interactive?
      end

      def edited_message(message)
        edited = normalize_message(AIGit::Prompt.edit(message))
        raise "Aborted: the edited commit message is empty." if edited.empty?

        print_message(edited)
        edited
      end

      def commit_and_push(message, branch, options)
        AIGit::Git.commit_with_message(message)
        AIGit::UI.success("Committed.")

        return AIGit::UI.info(AIGit::UI.dim("Skipped push (--no-push).")) unless options.push?

        return AIGit::UI.warning("Detached HEAD: skipping push. Commit is local only.") if branch.nil?

        AIGit::Git.push_current_branch
        AIGit::UI.success("Pushed to origin/#{branch}.")
      end

      def dry_run_summary(branch, options)
        outcome =
          if !options.push?
            "would commit only"
          elsif branch.nil?
            "would commit only (detached HEAD)"
          else
            "would commit and push to origin/#{branch}"
          end

        AIGit::UI.info(AIGit::UI.dim("Dry run: nothing changed, #{outcome}."))
      end

      def check_base_url!(options)
        return if AIGit::Config.loopback_base_url?

        host = AIGit::Config.base_uri.host

        if AIGit::Config.insecure_remote_base_url? && !options.force?
          raise "Refusing to send the staged diff unencrypted to #{host} over http. " \
                "Use https, a loopback address, or pass --force."
        end

        AIGit::UI.warning("Warning: the full staged diff will be sent to #{AIGit::Config.base_url} (not this machine).")
      end

      def check_secrets!(staged, diff, options)
        findings = AIGit::Secrets.scan(staged, diff)

        findings[:warnings].each { |finding| AIGit::UI.warning("Warning: #{finding}.") }

        blocking = findings[:blocking]
        return if blocking.empty?

        blocking.each { |finding| AIGit::UI.warning("Possible secret: #{finding}.") }
        return if options.force?

        raise "Refusing to send possible secrets to #{AIGit::Config.provider}. " \
              "Unstage these files or pass --force."
      end

      def print_header(provider, model_name, staged, branch)
        AIGit::UI.kv("AI Provider", provider)
        AIGit::UI.kv("Model", model_name)
        AIGit::UI.kv("Staged Files", staged.to_s.strip.gsub("\n", ", "))
        AIGit::UI.kv("Branch", branch || "(detached HEAD)")
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
