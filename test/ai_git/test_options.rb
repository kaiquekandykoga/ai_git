# frozen_string_literal: true
# test/ai_git/test_options.rb
#
# @purpose      Cover flag parsing: the unattended defaults, the long and short
#               forms, and the rejection of an unknown flag.
# @exports      Subject under test: AIGit::Options.
# @dependencies test/test_helper: loads the library and the test framework.
# @sideEffects  None.

require_relative "../test_helper"

class TestOptions < Test::Unit::TestCase
  def test_defaults_commit_and_push_unattended
    options = AIGit::Options.parse([])

    assert_false options.dry_run?
    assert_true options.push?
    assert_false options.assume_yes?
    assert_false options.force?
    assert_false options.help?
  end

  def test_parses_every_flag
    options = AIGit::Options.parse(["--dry-run", "--no-push", "--yes", "--force"])

    assert_true options.dry_run?
    assert_false options.push?
    assert_true options.assume_yes?
    assert_true options.force?
  end

  def test_parses_short_flags
    options = AIGit::Options.parse(["-n", "-y", "-f", "-h"])

    assert_true options.dry_run?
    assert_true options.assume_yes?
    assert_true options.force?
    assert_true options.help?
  end

  def test_unknown_flag_raises
    error = assert_raises(RuntimeError) { AIGit::Options.parse(["--nope"]) }
    assert_match(/Unknown option: --nope/, error.message)
  end
end
