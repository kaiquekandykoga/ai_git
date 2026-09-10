# frozen_string_literal: true
# test/ai_git/test_commit.rb
#
# @purpose      Cover the commit command: message normalizing, prompt
#               building, and the base-URL and secret guards.
# @exports      Subject under test: AIGit::Commands::Commit.
# @dependencies test/test_helper: loads the library, the framework, with_stub,
#               and with_settings;
#               stringio: captures the warnings the guards print.
# @sideEffects  Stubs AIGit::AIClient.complete and the resolved configuration
#               within blocks that restore both afterwards.
# @notes        The generator is always stubbed, so no test reaches the model
#               server or the repository.

require_relative "../test_helper"
require "stringio"

class TestCommit < Test::Unit::TestCase
  Commit = AIGit::Commands::Commit

  def test_commit_module_exists
    assert_kind_of Module, Commit
  end

  def test_commit_call_is_method
    assert_respond_to Commit, :call
  end

  def test_generate_commit_message_rejects_empty_diff
    assert_raises(RuntimeError) { Commit.generate_commit_message("", "model") }
    assert_raises(RuntimeError) { Commit.generate_commit_message("   \n", "model") }
  end

  def test_build_prompt_includes_diff
    diff = "diff --git a/foo b/foo\n+hello"
    prompt = Commit.build_prompt(diff)
    assert_include prompt, diff
    assert_include prompt, "STRICT OUTPUT FORMAT"
  end

  def test_normalize_message_inserts_blank_line_after_title
    assert_equal "Title\n\n## Summary\n- x", Commit.normalize_message("Title\n## Summary\n- x")
  end

  def test_normalize_message_keeps_existing_blank_line
    assert_equal "Title\n\n## Summary", Commit.normalize_message("Title\n\n## Summary")
  end

  def test_normalize_message_collapses_excess_blank_lines
    assert_equal "Title\n\n## Summary", Commit.normalize_message("Title\n\n\n\n## Summary")
  end

  def test_normalize_message_single_line_unchanged
    assert_equal "Just a title", Commit.normalize_message("Just a title")
  end

  def test_normalize_message_blank_input
    assert_equal "", Commit.normalize_message("")
  end

  def test_generate_commit_message_raises_on_empty_model_response
    ["", "   \n\n", nil].each do |response|
      with_stub(AIGit::AIClient, :complete, ->(**) { response }) do
        error = assert_raises(RuntimeError) { Commit.generate_commit_message("diff", "model") }
        assert_match(/empty commit message/, error.message)
      end
    end
  end

  def test_generate_commit_message_returns_normalized_message
    with_stub(AIGit::AIClient, :complete, ->(**) { "Title\nBody" }) do
      assert_equal "Title\n\nBody", Commit.generate_commit_message("diff", "model")
    end
  end

  def test_check_base_url_allows_loopback_silently
    with_settings("base_url" => "http://127.0.0.1:8080") do
      assert_nothing_raised { Commit.check_base_url!(AIGit::Options.parse([])) }
    end
  end

  def test_check_base_url_refuses_plain_http_to_a_remote_host
    with_settings("base_url" => "http://models.example.test") do
      error = assert_raises(RuntimeError) { Commit.check_base_url!(AIGit::Options.parse([])) }
      assert_match(/Refusing to send the staged diff unencrypted/, error.message)

      assert_nothing_raised { Commit.check_base_url!(AIGit::Options.parse(["--force"])) }
    end
  end

  def test_check_base_url_warns_for_a_remote_https_host
    with_settings("base_url" => "https://models.example.test") do
      warning = capture_stderr { Commit.check_base_url!(AIGit::Options.parse([])) }
      assert_match(%r{will be sent to https://models\.example\.test}, warning)
    end
  end

  def test_check_secrets_blocks_risky_paths_without_force
    capture_stderr do
      assert_raises(RuntimeError) { Commit.check_secrets!(".env\n", "+SECRET=1\n", AIGit::Options.parse([])) }
      assert_nothing_raised do
        Commit.check_secrets!(".env\n", "+SECRET=1\n", AIGit::Options.parse(["--force"]))
      end
    end
  end

  def test_check_secrets_allows_ordinary_changes
    assert_nothing_raised { Commit.check_secrets!("lib/a.rb\n", "+puts 1\n", AIGit::Options.parse([])) }
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end
end
