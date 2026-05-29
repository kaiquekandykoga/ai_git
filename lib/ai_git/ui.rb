# frozen_string_literal: true

require "shellwords"
require "tempfile"

module AIGit
  # Terminal output helpers: ANSI colors (auto-disabled when output is not a
  # TTY or NO_COLOR is set), key/value lines, prompts, and $EDITOR integration.
  module UI
    module_function

    CODES = {
      bold: 1, dim: 2, red: 31, green: 32, yellow: 33, blue: 34, cyan: 36, gray: 90
    }.freeze

    # Colors are on only for an interactive terminal and when the user has not
    # opted out via NO_COLOR (https://no-color.org) or AI_GIT_NO_COLOR.
    def color?
      return false if ENV["NO_COLOR"] && !ENV["NO_COLOR"].empty?
      return false if ENV["AI_GIT_NO_COLOR"] && !ENV["AI_GIT_NO_COLOR"].empty?

      $stdout.tty?
    end

    def paint(text, *styles)
      return text.to_s unless color?

      codes = styles.map { |style| CODES[style] }.compact
      return text.to_s if codes.empty?

      "\e[#{codes.join(';')}m#{text}\e[0m"
    end

    def bold(text)
      paint(text, :bold)
    end

    def dim(text)
      paint(text, :dim)
    end

    def kv(key, value)
      puts "#{paint("#{key}:", :bold)} #{value}"
    end

    def heading(text)
      puts paint(text, :bold, :cyan)
    end

    def info(text)
      puts text
    end

    def success(text)
      puts paint(text, :green)
    end

    def warn(text)
      $stderr.puts paint(text, :yellow) # rubocop:disable Style/StderrPuts
    end

    def error(text)
      $stderr.puts paint(text, :red) # rubocop:disable Style/StderrPuts
    end

    # Print a prompt (no newline) and return the typed line, stripped.
    def prompt(message)
      $stdout.print message
      $stdout.flush
      ($stdin.gets || "").strip
    end

    # Open `message` in the user's editor and return the edited text. Falls back
    # to the original message if the editor is cancelled or the result is empty.
    def edit_message(message)
      Tempfile.create(["ai_git_msg", ".txt"]) do |file|
        file.write(message)
        file.flush

        unless system("#{editor_command} #{Shellwords.escape(file.path)}")
          warn("Editor exited abnormally; keeping the original message.")
          return message
        end

        edited = File.read(file.path).strip
        edited.empty? ? message : edited
      end
    end

    # Resolve the editor git itself would use (honours core.editor, GIT_EDITOR,
    # VISUAL, EDITOR), falling back to vi.
    def editor_command
      resolved = `git var GIT_EDITOR 2>/dev/null`.strip
      return resolved unless resolved.empty?

      ENV["VISUAL"] || ENV["EDITOR"] || "vi"
    end
  end
end
