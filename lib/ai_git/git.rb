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
      result = `git rev-parse --abbrev-ref HEAD`
      result.chomp
    end

    def run_command(cmd, args)
      system("#{cmd} #{args}")
      raise "Command failed: #{cmd} #{args}" if $?.exitstatus != 0
    end
  end
end
