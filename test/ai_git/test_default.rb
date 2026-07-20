# frozen_string_literal: true

require_relative "../test_helper"

class TestDefault < Test::Unit::TestCase
  Default = AIGit::Commands::Default

  def test_default_module_exists
    assert_kind_of Module, Default
  end

  def test_default_call_is_method
    assert_respond_to Default, :call
  end

  def test_generate_commit_message_rejects_empty_diff
    assert_raises(RuntimeError) { Default.generate_commit_message("", "model") }
    assert_raises(RuntimeError) { Default.generate_commit_message("   \n", "model") }
  end

  def test_build_prompt_includes_diff
    diff = "diff --git a/foo b/foo\n+hello"
    prompt = Default.build_prompt(diff)
    assert_include prompt, diff
    assert_include prompt, "STRICT OUTPUT FORMAT"
  end

  def test_normalize_message_inserts_blank_line_after_title
    assert_equal "Title\n\n## Summary\n- x", Default.normalize_message("Title\n## Summary\n- x")
  end

  def test_normalize_message_keeps_existing_blank_line
    assert_equal "Title\n\n## Summary", Default.normalize_message("Title\n\n## Summary")
  end

  def test_normalize_message_collapses_excess_blank_lines
    assert_equal "Title\n\n## Summary", Default.normalize_message("Title\n\n\n\n## Summary")
  end

  def test_normalize_message_single_line_unchanged
    assert_equal "Just a title", Default.normalize_message("Just a title")
  end

  def test_normalize_message_blank_input
    assert_equal "", Default.normalize_message("")
  end
end
