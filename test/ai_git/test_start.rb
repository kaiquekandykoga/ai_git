# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class TestStart < Test::Unit::TestCase
  def with_captured_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def test_help_flag_prints_usage
    out = with_captured_stdout { AIGit.start(["--help"]) }
    assert_include out, "Usage: ai_git"
  end

  def test_version_flag_prints_version
    out = with_captured_stdout { AIGit.start(["--version"]) }
    assert_include out, AIGit::VERSION
  end

  def test_unknown_subcommand_exits_nonzero
    original_stderr = $stderr
    $stderr = StringIO.new
    assert_raises(SystemExit) { AIGit.start(["does-not-exist"]) }
  ensure
    $stderr = original_stderr
  end

  def test_config_subcommand_prints_configuration
    out = with_captured_stdout { AIGit.start(["config"]) }
    assert_include out, "ai_git configuration"
    assert_include out, "Provider:"
    assert_include out, "llama_cpp"
  end
end
