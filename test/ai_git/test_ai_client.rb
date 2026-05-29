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

  def test_anthropic_complete_requires_api_key
    original = {
      "AI_GIT_API_KEY" => ENV["AI_GIT_API_KEY"],
      "ANTHROPIC_API_KEY" => ENV["ANTHROPIC_API_KEY"]
    }
    original.each_key { |k| ENV.delete(k) }

    error = assert_raises(RuntimeError) do
      AIGit::AIClient.anthropic_complete("prompt", "claude-opus-4-7", 0.2, 1024, nil)
    end
    assert_match(/API_KEY/, error.message)
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def test_azure_complete_requires_api_key
    original = {
      "AI_GIT_API_KEY" => ENV["AI_GIT_API_KEY"],
      "AZURE_OPENAI_API_KEY" => ENV["AZURE_OPENAI_API_KEY"]
    }
    original.each_key { |k| ENV.delete(k) }

    error = assert_raises(RuntimeError) do
      AIGit::AIClient.azure_complete("prompt", "gpt-4o-mini", 0.2)
    end
    assert_match(/API_KEY/, error.message)
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
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
    original = ENV["AI_GIT_AI_PROVIDER"]
    ENV.delete("AI_GIT_AI_PROVIDER") # defaults to jan (local)
    message = AIGit::AIClient.connection_error_message(Errno::ECONNREFUSED.new("boom"))
    assert_match(/Cannot reach jan/, message)
    assert_match(/after #{AIGit::AIClient::MAX_ATTEMPTS} attempts/, message)
    assert_match(/local server running/, message)
  ensure
    original.nil? ? ENV.delete("AI_GIT_AI_PROVIDER") : ENV["AI_GIT_AI_PROVIDER"] = original
  end

  def test_connection_error_message_hints_hosted_provider
    original = ENV["AI_GIT_AI_PROVIDER"]
    ENV["AI_GIT_AI_PROVIDER"] = "claude"
    message = AIGit::AIClient.connection_error_message(Errno::ECONNREFUSED.new("boom"))
    assert_match(/Cannot reach claude/, message)
    assert_match(/network connection/, message)
  ensure
    original.nil? ? ENV.delete("AI_GIT_AI_PROVIDER") : ENV["AI_GIT_AI_PROVIDER"] = original
  end

  def test_http_error_message_includes_status_and_hints
    response = Struct.new(:code, :body).new("401", "unauthorized")
    message = AIGit::AIClient.http_error_message(URI("http://example.test/v1"), response)
    assert_match(/HTTP 401/, message)
    assert_match(/AI_GIT_API_KEY/, message)

    not_found = Struct.new(:code, :body).new("404", "missing")
    assert_match(/model name/, AIGit::AIClient.http_error_message(URI("http://example.test/v1"), not_found))
  end
end
