# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

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

  def test_build_prompt_standard_is_not_conventional
    assert_false Default.build_prompt("diff").include?("Conventional Commits")
  end

  def test_build_prompt_conventional_includes_spec_and_diff
    diff = "diff --git a/foo b/foo\n+hello"
    prompt = Default.build_prompt(diff, conventional: true)
    assert_include prompt, diff
    assert_include prompt, "Conventional Commits"
    assert_include prompt, "feat"
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

  def test_interactive_is_false_when_yes
    opts = AIGit::Options.new(yes: true)
    assert_false Default.interactive?(opts)
  end

  def feed(input)
    out = $stdout
    inp = $stdin
    $stdout = StringIO.new
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdout = out
    $stdin = inp
  end

  def test_prompt_action_accept_on_a_or_enter
    feed("a\n") { assert_equal :accept, Default.prompt_action(true) }
    feed("\n")  { assert_equal :accept, Default.prompt_action(true) }
  end

  def test_prompt_action_edit_regenerate_quit
    feed("e\n") { assert_equal :edit, Default.prompt_action(true) }
    feed("r\n") { assert_equal :regenerate, Default.prompt_action(true) }
    feed("q\n") { assert_equal :quit, Default.prompt_action(true) }
  end

  def test_prompt_action_skip_push_only_when_push_enabled
    feed("s\n") { assert_equal :commit_only, Default.prompt_action(true) }
    # When push is disabled, 's' is not offered; fall through to the next input.
    feed("s\nq\n") { assert_equal :quit, Default.prompt_action(false) }
  end
end
