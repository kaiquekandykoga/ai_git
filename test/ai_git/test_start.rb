# frozen_string_literal: true
# test/ai_git/test_start.rb
#
# @purpose      Cover the CLI router: the help and version flags, subcommand
#               dispatch, and the exit on an unknown subcommand.
# @exports      Subject under test: AIGit.start.
# @dependencies test/test_helper: loads the library, the test framework, and
#               with_config_dir;
#               stringio: captures what the router prints.
# @sideEffects  Replaces $stdout within a block that restores it, points the
#               configuration at a temporary directory, and asserts on the
#               SystemExit raised by the unknown-subcommand path.

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
    assert_include out, "Config file:"
  end

  def test_config_subcommand_names_the_config_file
    with_config_dir("model_name: shown-model\n") do |dir|
      out = with_captured_stdout { AIGit.start(["config"]) }
      assert_include out, "shown-model"
      assert_include out, File.join(dir, "config.yml")
    end
  end

  def test_config_subcommand_prints_nothing_for_a_broken_config_file
    with_config_dir("modelname: typo\n") do
      original = $stdout
      $stdout = StringIO.new
      error = assert_raises(RuntimeError) { AIGit.start(["config"]) }
      assert_match(/Unknown setting/, error.message)
      assert_equal "", $stdout.string
    ensure
      $stdout = original
    end
  end

  def test_config_subcommand_marks_a_missing_config_file
    with_config_dir(nil) do |dir|
      out = with_captured_stdout { AIGit.start(["config"]) }
      assert_include out, "#{File.join(dir, 'config.yml')} (not found)"
    end
  end
end
