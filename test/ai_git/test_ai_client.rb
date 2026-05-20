# frozen_string_literal: true

require_relative "../test_helper"

class TestAIClient < Test::Unit::TestCase
  def test_sanitize_drops_lines_starting_with_noise_prefix
    raw = "Output: extra preamble\nActual content line"
    assert_equal "Actual content line", AIGit::AIClient.sanitize(raw)
  end

  def test_sanitize_strips_leading_markdown_header_tokens
    raw = "```Actual content line"
    assert_equal "Actual content line", AIGit::AIClient.sanitize(raw)
  end

  def test_sanitize_unescapes_literal_newlines
    assert_equal "line1\nline2", AIGit::AIClient.sanitize('line1\nline2')
  end

  def test_sanitize_handles_nil
    assert_equal "", AIGit::AIClient.sanitize(nil)
  end

  def test_sanitize_strips_blockquote_marker
    assert_equal "content", AIGit::AIClient.sanitize("> content")
  end
end
