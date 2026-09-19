# frozen_string_literal: true

module AIGit
  class Options
    attr_accessor :dry_run, :push, :assume_yes, :force, :help

    def initialize
      @dry_run = false
      @push = true
      @assume_yes = false
      @force = false
      @help = false
    end

    def self.parse(argv)
      argv.to_a.each_with_object(new) do |arg, options|
        case arg
        when "-n", "--dry-run" then options.dry_run = true
        when "--no-push"       then options.push = false
        when "-y", "--yes"     then options.assume_yes = true
        when "-f", "--force"   then options.force = true
        when "-h", "--help"    then options.help = true
        else raise "Unknown option: #{arg}. Run `ai_git --help` for usage."
        end
      end
    end

    def dry_run?
      @dry_run
    end

    def push?
      @push
    end

    def assume_yes?
      @assume_yes
    end

    def force?
      @force
    end

    def help?
      @help
    end
  end
end
