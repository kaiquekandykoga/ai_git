# frozen_string_literal: true

require "benchmark"
require_relative "version"
require_relative "git"
require_relative "ollama"

module AIGit
  module Default
    def self.call
      model_name = ENV["AI_GIT_MODEL_NAME"] || "phi4:14b"

      staged = AIGit::Git.staged_files
      abort "Error: No staged files. Use `git add` first." if staged.to_s.strip.empty?

      diff = AIGit::Git.diff
      branch = AIGit::Git.current_branch

      puts "\e[1mModel Name:\e[0m #{model_name}"
      puts "\e[1mStaged Files:\e[0m #{staged}"
      puts "\e[1mBranch:\e[0m #{branch}"
      puts "\e[1mAI Generating Commit Message\e[0m"

      result = Benchmark.measure do
        message = AIGit::Ollama.generate_commit_message(diff, model_name)
        message = message.gsub(/\n{2,}/, "\n")

        puts "\e[1mCommit Message:\e[0m\n\n#{message}\n"

        escaped_msg = message.gsub(/[\\"`$]/) { |c| "\\#{c}" }
        AIGit::Git.run_command("git", "commit -m \"#{escaped_msg}\"")
        puts "\e[1mGit Commited\e[0m"

        AIGit::Git.run_command("git", "push")
        puts "\e[1mGit Pushed\e[0m"
      end

      puts "\e[1mBenchmark\e[0m"
      puts result
    end
  end
end
