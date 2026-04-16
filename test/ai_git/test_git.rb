require_relative '../test_helper'

class TestGit < Test::Unit::TestCase
  def test_version
    assert_equal '0.0.3', AIGit::VERSION
  end

  def test_staged_files_returns_string
    result = AIGit::Git.staged_files
    assert_kind_of String, result
  end

  def test_diff_returns_string
    result = AIGit::Git.diff
    assert_kind_of String, result
  end

  def test_current_branch_returns_string
    result = AIGit::Git.current_branch
    assert_kind_of String, result
    assert_false result.empty?
  end

  def test_run_command_raises_on_failure
    assert_raises(RuntimeError) { AIGit::Git.run_command('false', '') }
  end
end
