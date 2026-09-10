# frozen_string_literal: true
# test/ai_git/test_start.rb
#
# @purpose      Cover the CLI router: the bare invocation that does nothing,
#               the help and version flags, subcommand dispatch, and the exit
#               on an unknown subcommand or option.
# @exports      Subject under test: AIGit.start.
# @dependencies test/test_helper: loads the library, the test framework,
#               with_stub, and with_config_dir;
#               stringio: captures what the router prints.
# @sideEffects  Replaces $stdout within a block that restores it, points the
#               configuration at a temporary directory, stubs the commit
#               command to keep dispatch off the repository, and asserts on
#               the SystemExit raised by the unknown-argument paths.

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

  def test_no_arguments_does_nothing
    calls = []
    with_stub(AIGit::Commands::Commit, :call, ->(*args) { calls << args }) do
      out = with_captured_stdout { AIGit.start([]) }
      assert_include out, "ai_git help"
      assert_not_include out, "Subcommands:"
    end
    assert_empty calls
  end

  def test_commit_subcommand_dispatches_to_the_commit_command
    calls = []
    with_stub(AIGit::Commands::Commit, :call, ->(*args) { calls << args }) do
      AIGit.start(["commit", "--dry-run"])
    end
    assert_equal [[["--dry-run"]]], calls
  end

  def test_help_subcommand_prints_usage
    out = with_captured_stdout { AIGit.start(["help"]) }
    assert_include out, "Usage: ai_git"
    assert_include out, "commit"
  end

  def test_help_subcommand_describes_a_named_subcommand
    out = with_captured_stdout { AIGit.start(%w[help commit]) }
    assert_include out, "Usage: ai_git commit"
    assert_include out, "--dry-run"
  end

  def test_unknown_option_exits_nonzero_without_running_a_command
    original_stderr = $stderr
    $stderr = StringIO.new
    calls = []
    with_stub(AIGit::Commands::Commit, :call, ->(*args) { calls << args }) do
      assert_raises(SystemExit) { AIGit.start(["--dry-run"]) }
    end
    assert_include $stderr.string, "Unknown option: --dry-run"
    assert_empty calls
  ensure
    $stderr = original_stderr
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
      assert_include out, "#{File.join(dir, "config.yml")} (not found)"
    end
  end
end
