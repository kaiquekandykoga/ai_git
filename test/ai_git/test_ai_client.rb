# frozen_string_literal: true
# test/ai_git/test_ai_client.rb
#
# @purpose      Cover the reply sanitizing, retry classification, and error
#               messages of the chat client.
# @exports      Subject under test: AIGit::AIClient.
# @dependencies test/test_helper: loads the library and the test framework.
# @sideEffects  None.
# @notes        Nothing here touches the network: the tests exercise the pure
#               helpers around the request rather than the request itself.

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

  def test_sanitize_unescapes_a_fully_escaped_single_line_message
    assert_equal "Title\n\nBody", AIGit::AIClient.sanitize('Title\n\nBody')
  end

  def test_sanitize_keeps_literal_backslash_n_inside_prose
    raw = "Use \\n in the format string."
    assert_equal raw, AIGit::AIClient.sanitize(raw)
  end

  def test_sanitize_keeps_body_lines_that_start_with_noise_words
    raw = "Fix parser crash\n\nThe changes to the lexer were needed.\nBased on profiling, we cache tokens."
    assert_equal raw, AIGit::AIClient.sanitize(raw)
  end

  def test_sanitize_drops_only_the_leading_preamble_block
    raw = "Here is the commit message:\n\nFix parser crash\n\nThe changes helped."
    assert_equal "Fix parser crash\n\nThe changes helped.", AIGit::AIClient.sanitize(raw)
  end

  def test_sanitize_strips_surrounding_code_fences
    assert_equal "Title\n\nBody", AIGit::AIClient.sanitize("```\nTitle\n\nBody\n```")
  end

  def test_sanitize_handles_nil
    assert_equal "", AIGit::AIClient.sanitize(nil)
  end

  def test_sanitize_strips_blockquote_marker
    assert_equal "content", AIGit::AIClient.sanitize("> content")
  end

  def test_transient_status_classification
    [408, 425, 429, 500, 502, 503, 504].each do |code|
      assert_true AIGit::AIClient.transient_status?(code), "#{code} should be transient"
      assert_true AIGit::AIClient.transient_status?(code.to_s)
    end
    [200, 201, 400, 401, 403, 404].each do |code|
      assert_false AIGit::AIClient.transient_status?(code), "#{code} should not be transient"
    end
  end

  def test_retry_delay_grows_exponentially
    assert_equal 0.5, AIGit::AIClient.retry_delay(1)
    assert_equal 1.0, AIGit::AIClient.retry_delay(2)
    assert_equal 2.0, AIGit::AIClient.retry_delay(3)
  end

  def test_connection_error_message_hints_local_provider
    message = AIGit::AIClient.connection_error_message(Errno::ECONNREFUSED.new("boom"))
    assert_match(/Cannot reach llama_cpp/, message)
    assert_match(/after #{AIGit::AIClient::MAX_ATTEMPTS} attempts/, message)
    assert_match(/local server running/, message)
  end

  def test_http_error_message_includes_status_and_hints
    response = Struct.new(:code, :body).new("401", "unauthorized")
    message = AIGit::AIClient.http_error_message(URI("http://example.test/v1"), response)
    assert_match(/HTTP 401/, message)

    not_found = Struct.new(:code, :body).new("404", "missing")
    assert_match(/model name/, AIGit::AIClient.http_error_message(URI("http://example.test/v1"), not_found))
  end
end
