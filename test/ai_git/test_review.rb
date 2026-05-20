# frozen_string_literal: true

require_relative "../test_helper"

class TestReview < Test::Unit::TestCase
  def test_review_module_exists
    assert_kind_of Module, AIGit::Commands::Review
  end

  def test_review_call_is_method
    assert_respond_to AIGit::Commands::Review, :call
  end

  def test_generate_review_rejects_empty_diff
    assert_raises(RuntimeError) { AIGit::Commands::Review.generate_review("", "model") }
  end

  def test_build_prompt_includes_diff
    diff = "diff --git a/foo b/foo\n+hello"
    prompt = AIGit::Commands::Review.build_prompt(diff)
    assert_include prompt, diff
    assert_include prompt, "Verdict"
  end
end
