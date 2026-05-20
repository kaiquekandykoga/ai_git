# frozen_string_literal: true

require_relative "../test_helper"

class TestDefault < Test::Unit::TestCase
  def test_default_module_exists
    assert_kind_of Module, AIGit::Commands::Default
  end

  def test_default_call_is_method
    assert_respond_to AIGit::Commands::Default, :call
  end

  def test_generate_commit_message_rejects_empty_diff
    assert_raises(RuntimeError) { AIGit::Commands::Default.generate_commit_message("", "model") }
    assert_raises(RuntimeError) { AIGit::Commands::Default.generate_commit_message("   \n", "model") }
  end

  def test_build_prompt_includes_diff
    diff = "diff --git a/foo b/foo\n+hello"
    prompt = AIGit::Commands::Default.build_prompt(diff)
    assert_include prompt, diff
    assert_include prompt, "STRICT OUTPUT FORMAT"
  end
end
