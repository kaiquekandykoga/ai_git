# frozen_string_literal: true

require "English"
require "open3"
require "tempfile"

module AIGit
  module Git
    module_function

    def staged_files
      `git diff --cached --name-only`
    end

    def diff
      `git diff --cached`
    end

    # Stage every change (new, modified, deleted) in the working tree.
    def stage_all
      run_command("git", "add", "-A")
    end

    # Diff that the amended commit will contain: the index compared against the
    # previous commit's parent. Falls back to the staged diff when amending the
    # root commit (no parent exists).
    def amend_diff
      `git rev-parse --verify --quiet HEAD~1`
      $CHILD_STATUS.success? ? `git diff --cached HEAD~1` : `git diff --cached`
    end

    def current_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    # Run a command with arguments as an array — no shell, so values are not
    # interpolated or word-split. Accepts either:
    #   run_command("git", "status")                  (single string of args)
    #   run_command("git", "commit", "-m", message)   (variadic args, preferred)
    def run_command(cmd, *args)
      argv =
        if args.length == 1 && args.first.is_a?(String)
          args.first.split
        else
          args.map(&:to_s)
        end

      _stdout, stderr, status = Open3.capture3(cmd, *argv)

      return if status.success?

      raise "Command failed: #{cmd} #{argv.join(' ')} (exit #{status.exitstatus})#{stderr.empty? ? '' : "\n#{stderr}"}"
    end

    # Commit using a temp file so the message can contain anything (quotes,
    # backticks, dollar signs) without shell-escaping concerns. Pass amend: true
    # to rewrite the last commit instead of creating a new one.
    def commit_with_message(message, amend: false)
      Tempfile.create("ai_git_commit_msg") do |file|
        file.write(message)
        file.flush

        args = ["commit", "-F", file.path]
        args << "--amend" if amend
        run_command("git", *args)
      end
    end

    def push_current_branch
      run_command("git", "push", "-u", "origin", "HEAD")
    end
  end
end
