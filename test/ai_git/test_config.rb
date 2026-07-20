# frozen_string_literal: true

require_relative "../test_helper"

class TestConfig < Test::Unit::TestCase
  def setup
    @original_env = {
      "AI_GIT_MODEL_NAME" => ENV["AI_GIT_MODEL_NAME"],
      "AI_GIT_BASE_URL" => ENV["AI_GIT_BASE_URL"]
    }
    @original_env.each_key { |k| ENV.delete(k) }
  end

  def teardown
    @original_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def test_provider_is_llama_cpp
    assert_equal "llama_cpp", AIGit::Config.provider
  end

  def test_model_name_defaults_to_default
    assert_equal "ggml-org/gemma-4-E4B-it-GGUF:Q8_0", AIGit::Config.model_name
  end

  def test_model_name_uses_env_override
    ENV["AI_GIT_MODEL_NAME"] = "custom-model"
    assert_equal "custom-model", AIGit::Config.model_name
  end

  def test_base_url_defaults_to_local_llama_cpp_server
    assert_equal "http://127.0.0.1:8080", AIGit::Config.base_url
  end

  def test_base_url_uses_env_override
    ENV["AI_GIT_BASE_URL"] = "http://example.test:1234"
    assert_equal "http://example.test:1234", AIGit::Config.base_url
  end

  def test_endpoint_is_openai_chat_completions
    assert_equal "/v1/chat/completions", AIGit::Config.endpoint
  end
end
