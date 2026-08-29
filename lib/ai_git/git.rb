# frozen_string_literal: true
# lib/ai_git/git.rb
#
# @purpose      Wrap the git porcelain this tool drives: inspect the staged
#               tree, then commit and push on the user's behalf.
# @exports      AIGit::Git: NOT_A_REPOSITORY, MAX_ERROR_DETAIL, .repository?,
#               .ensure_repository!, .staged_files, .diff, .current_branch,
#               .detached_head?, .commit_with_message, .push_current_branch.
# @dependencies git: every operation shells out to the binary;
#               open3: captures stdout, stderr, and exit status together;
#               tempfile: holds the commit message passed to `git commit -F`.
# @sideEffects  Spawns git subprocesses; writes a tempfile; mutates the
#               repository and the remote on commit and push.
# @notes        Raises a bare string message; bin/ai_git renders it and exits 1.

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
