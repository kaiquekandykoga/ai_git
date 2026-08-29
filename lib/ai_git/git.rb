# frozen_string_literal: true

require "open3"
require "tempfile"

module AIGit
  module Git
    module_function

    NOT_A_REPOSITORY = "Not a git repository (or any of the parent directories)."
    MAX_ERROR_DETAIL = 500

    def repository?
      _stdout, _stderr, status = Open3.capture3("git", "rev-parse", "--git-dir")
      status.success?
    end

    def ensure_repository!
      raise NOT_A_REPOSITORY unless repository?
    end

    def staged_files
      ensure_repository!
      capture("git", "diff", "--cached", "--name-only")
    end

    def diff
      ensure_repository!
      capture("git", "diff", "--cached")
    end

    # Returns the checked-out branch name, or nil when HEAD is detached.
    def current_branch
      ensure_repository!
      stdout, _stderr, status = Open3.capture3("git", "symbolic-ref", "--quiet", "--short", "HEAD")
      return nil unless status.success?

      branch = stdout.chomp
      branch.empty? ? nil : branch
    end

    def detached_head?
      current_branch.nil?
    end

    def capture(*argv)
      stdout, stderr, status = Open3.capture3(*argv)
      return stdout if status.success?

      raise command_error(argv, stderr, status)
    end

    def run_command(cmd, *args)
      argv = [cmd, *args.map(&:to_s)]
      _stdout, stderr, status = Open3.capture3(*argv)

      return if status.success?

      raise command_error(argv, stderr, status)
    end

    def command_error(argv, stderr, status)
      detail = stderr.to_s.strip
      detail = "#{detail[0, MAX_ERROR_DETAIL]}…" if detail.length > MAX_ERROR_DETAIL
      header = "Command failed: #{argv.join(' ')} (exit #{status.exitstatus})"

      detail.empty? ? header : "#{header}\n#{detail}"
    end

    def commit_with_message(message)
      Tempfile.create("ai_git_commit_msg") do |file|
        file.write(message)
        file.flush

        run_command("git", "commit", "-F", file.path)
      end
    end

    def push_current_branch
      run_command("git", "push", "-u", "origin", "HEAD")
    end
  end
end
