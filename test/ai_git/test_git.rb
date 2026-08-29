# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

class TestGit < Test::Unit::TestCase
  def in_temp_repo
    Dir.mktmpdir("ai_git_test") do |dir|
      Dir.chdir(dir) do
        run_git("init")
        run_git("symbolic-ref", "HEAD", "refs/heads/main")
        run_git("config", "user.email", "test@example.test")
        run_git("config", "user.name", "Test")
        yield dir
      end
    end
  end

  def run_git(*args)
    stdout, stderr, status = Open3.capture3("git", *args)
    raise "git #{args.join(' ')} failed: #{stderr}" unless status.success?

    stdout
  end

  def commit_file(name, content)
    File.write(name, content)
    run_git("add", name)
    run_git("commit", "-m", "add #{name}")
  end

  def test_staged_files_lists_staged_paths
    in_temp_repo do
      File.write("a.txt", "hello\n")
      run_git("add", "a.txt")
      assert_equal "a.txt\n", AIGit::Git.staged_files
    end
  end

  def test_diff_contains_staged_content
    in_temp_repo do
      File.write("a.txt", "hello\n")
      run_git("add", "a.txt")
      assert_include AIGit::Git.diff, "+hello"
    end
  end

  def test_current_branch_returns_checked_out_branch
    in_temp_repo do
      commit_file("a.txt", "hello\n")
      assert_equal "main", AIGit::Git.current_branch
      assert_false AIGit::Git.detached_head?
    end
  end

  def test_current_branch_is_nil_when_head_is_detached
    in_temp_repo do
      commit_file("a.txt", "hello\n")
      run_git("checkout", "--detach", "HEAD")

      assert_nil AIGit::Git.current_branch
      assert_true AIGit::Git.detached_head?
    end
  end

  def test_read_commands_raise_outside_a_repository
    Dir.mktmpdir("ai_git_not_a_repo") do |dir|
      Dir.chdir(dir) do
        assert_false AIGit::Git.repository?
        error = assert_raises(RuntimeError) { AIGit::Git.staged_files }
        assert_equal AIGit::Git::NOT_A_REPOSITORY, error.message
        assert_raises(RuntimeError) { AIGit::Git.diff }
        assert_raises(RuntimeError) { AIGit::Git.current_branch }
      end
    end
  end

  def test_repository_predicate_is_true_inside_a_repo
    in_temp_repo { assert_true AIGit::Git.repository? }
  end

  def test_run_command_raises_on_failure
    assert_raises(RuntimeError) { AIGit::Git.run_command("false") }
  end

  def test_run_command_accepts_array_args
    AIGit::Git.run_command("true", "ignored", "args")
  end

  def test_run_command_preserves_spaces_in_a_single_argument
    Dir.mktmpdir("ai_git space") do |dir|
      AIGit::Git.run_command("test", "-d", dir)
    end
  end
end
