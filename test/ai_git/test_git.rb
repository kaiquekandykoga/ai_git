# frozen_string_literal: true

require_relative "../test_helper"

class TestGit < Test::Unit::TestCase
  def test_staged_files_returns_string
    assert_kind_of String, AIGit::Git.staged_files
  end

  def test_diff_returns_string
    assert_kind_of String, AIGit::Git.diff
  end

  unless freebsd?
    def test_current_branch_returns_string
      result = AIGit::Git.current_branch
      assert_kind_of String, result
      assert_false result.empty?
    end
  end

  def test_run_command_raises_on_failure
    assert_raises(RuntimeError) { AIGit::Git.run_command("false") }
  end

  def test_run_command_accepts_array_args
    # Should not raise — `true` always exits 0.
    AIGit::Git.run_command("true", "ignored", "args")
  end

  def test_run_command_legacy_string_args
    # Single string of args is split on whitespace for backward compatibility.
    AIGit::Git.run_command("true", "a b c")
  end
end
