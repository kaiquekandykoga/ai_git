# frozen_string_literal: true

module AIGit
  module UI
    module_function

    CODES = {
      bold: 1, dim: 2, red: 31, green: 32, yellow: 33, blue: 34, cyan: 36, gray: 90
    }.freeze

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

    def warning(text)
      warn paint(text, :yellow)
    end

    def error(text)
      $stderr.puts paint(text, :red) # rubocop:disable Style/StderrPuts
    end
  end
end
