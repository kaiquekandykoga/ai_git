# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class TestOptions < Test::Unit::TestCase
  def parse(argv, command: "default")
    AIGit::OptionsParser.parse(argv, command: command)
  end

  def silence_streams
    out = $stdout
    err = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = out
    $stderr = err
  end

  def test_defaults_are_all_false
    opts = parse([])
    assert_false opts.yes
    assert_false opts.no_push
    assert_false opts.dry_run
    assert_false opts.amend
    assert_false opts.conventional
    assert_false opts.all
  end

  def test_yes_flag
    assert_true parse(["--yes"]).yes
    assert_true parse(["-y"]).yes
  end

  def test_no_push_flag
    assert_true parse(["--no-push"]).no_push
    assert_false parse(["--push"]).no_push
  end

  def test_dry_run_amend_conventional_all
    assert_true parse(["--dry-run"]).dry_run
    assert_true parse(["--amend"]).amend
    assert_true parse(["--conventional"]).conventional
    assert_true parse(["--all"]).all
    assert_true parse(["-a"]).all
  end

  def test_combined_flags
    opts = parse(["--all", "--yes", "--no-push", "--conventional"])
    assert_true opts.all
    assert_true opts.yes
    assert_true opts.no_push
    assert_true opts.conventional
  end

  def test_unknown_flag_exits_nonzero
    error = assert_raises(SystemExit) { silence_streams { parse(["--nope"]) } }
    assert_equal 1, error.status
  end

  def test_help_flag_exits_zero
    error = assert_raises(SystemExit) { silence_streams { parse(["--help"]) } }
    assert_equal 0, error.status
  end

  def test_review_accepts_all_but_not_commit_flags
    assert_true parse(["--all"], command: "review").all
    error = assert_raises(SystemExit) { silence_streams { parse(["--amend"], command: "review") } }
    assert_equal 1, error.status
  end

  def test_config_rejects_command_flags
    error = assert_raises(SystemExit) { silence_streams { parse(["--all"], command: "config") } }
    assert_equal 1, error.status
  end
end
