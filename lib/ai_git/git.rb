# frozen_string_literal: true
# lib/ai_git/git.rb
#
# @purpose      Wrap the git porcelain this tool drives: inspect the staged
#               tree, then commit and push on the user's behalf.
# @exports      AIGit::Git: NOT_A_REPOSITORY, MAX_ERROR_DETAIL, REPLACEMENT,
#               .repository?, .ensure_repository!, .staged_files, .diff,
#               .current_branch, .detached_head?, .scrub,
#               .commit_with_message, .push_current_branch.
# @dependencies git: every operation shells out to the binary;
#               open3: captures stdout, stderr, and exit status together;
#               tempfile: holds the commit message passed to `git commit -F`.
# @sideEffects  Spawns git subprocesses; writes a tempfile; mutates the
#               repository and the remote on commit and push.
# @notes        Raises a bare string message; bin/ai_git renders it and exits 1.
#               Captured output is scrubbed to valid UTF-8 so a diff of a
#               non-UTF-8 file cannot break JSON encoding downstream.

require "open3"
require "tempfile"

module AIGit
  module Git
    module_function

    NOT_A_REPOSITORY = "Not a git repository (or any of the parent directories)."
    MAX_ERROR_DETAIL = 500
    REPLACEMENT = "\uFFFD"

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
      return scrub(stdout) if status.success?

      raise command_error(argv, stderr, status)
    end

    # git hands back the bytes it stored, whatever they are. A Latin-1 file
    # makes the diff invalid UTF-8, which the JSON encoder in the HTTP client
    # refuses; replace the offending bytes here, at the source.
    def scrub(text)
      string = text.to_s
      string = string.dup.force_encoding(Encoding::UTF_8) unless string.encoding == Encoding::UTF_8
      string.valid_encoding? ? string : string.scrub(REPLACEMENT)
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
