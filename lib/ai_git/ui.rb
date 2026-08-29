# frozen_string_literal: true
# lib/ai_git/ui.rb
#
# @purpose      Render every line the CLI prints, adding ANSI color only when
#               the terminal and the configuration both allow it.
# @exports      AIGit::UI: CODES, .color?, .no_color?, .paint, .bold, .dim,
#               .kv, .heading, .info, .success, .warning, .error.
# @dependencies ai_git/config: supplies the no_color setting from
#               ~/.ai_git/config.yml.
# @sideEffects  Writes to stdout and stderr; inspects $stdout.tty?.
# @notes        Color is off whenever the config file sets no_color or stdout
#               is not a terminal, so piped output stays plain. A config file
#               that fails to load also turns color off rather than raising, so
#               that error itself can still be printed.

require_relative "config"

module AIGit
  module UI
    module_function

    CODES = {
      bold: 1, dim: 2, red: 31, green: 32, yellow: 33, blue: 34, cyan: 36, gray: 90
    }.freeze

    def color?
      return false if no_color?

      $stdout.tty?
    end

    def no_color?
      AIGit::Config.no_color?
    rescue StandardError
      true
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

    def warning(text)
      warn paint(text, :yellow)
    end

    def error(text)
      $stderr.puts paint(text, :red) # rubocop:disable Style/StderrPuts
    end
  end
end
