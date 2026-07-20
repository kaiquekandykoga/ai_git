# frozen_string_literal: true

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

    def current_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

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
