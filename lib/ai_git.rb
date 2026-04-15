require_relative 'ai_git/version'
require_relative 'ai_git/git'
require_relative 'ai_git/ollama'

module AIGit
  module_function

  def run
    staged = AIGit::Git.staged_files
    abort 'Error: No staged files. Use `git add` first.' if staged.to_s.strip.empty?

    diff = AIGit::Git.diff
    branch = AIGit::Git.current_branch

    puts "\e[1mStaged Files:\e[0m #{staged}"
    puts "\e[1mBranch:\e[0m #{branch}"
    puts "\e[1mAI Generating Commit Message\e[0m"

    message = AIGit::Ollama.generate_commit_message(diff)
    message = message.gsub(/\n{2,}/, "\n")

    puts "Commit Message:\n#{message}"

    escaped_msg = message.gsub(/[\\"`$]/) { |c| "\\#{c}" }
    AIGit::Git.run_command('git', "commit -m \"#{escaped_msg}\"")
    puts "Git Committed"

    AIGit::Git.run_command('git', 'push')
    puts "Git Pushed"
  end
end
