# frozen_string_literal: true

require_relative "../test_helper"

class TestConfig < Test::Unit::TestCase
  def setup
    @original_env = {
      "AI_GIT_AI_PROVIDER" => ENV["AI_GIT_AI_PROVIDER"],
      "AI_GIT_MODEL_NAME" => ENV["AI_GIT_MODEL_NAME"],
      "AI_GIT_BASE_URL" => ENV["AI_GIT_BASE_URL"]
    }
    @original_env.each_key { |k| ENV.delete(k) }
  end

  def teardown
    @original_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def test_provider_defaults_to_jan
    assert_equal "jan", AIGit::Config.provider
  end

  def test_provider_can_be_set_to_ollama
    ENV["AI_GIT_AI_PROVIDER"] = "ollama"
    assert_equal "ollama", AIGit::Config.provider
  end

  def test_provider_rejects_unknown
    ENV["AI_GIT_AI_PROVIDER"] = "bogus"
    assert_raises(RuntimeError) { AIGit::Config.provider }
  end

  def test_model_name_falls_back_to_provider_default
    assert_equal "Jan-v3.5-4B-Q4_K_XL", AIGit::Config.model_name
  end

  def test_model_name_uses_env_override
    ENV["AI_GIT_MODEL_NAME"] = "custom-model"
    assert_equal "custom-model", AIGit::Config.model_name
  end

  def test_base_url_uses_env_override
    ENV["AI_GIT_BASE_URL"] = "http://example.test:1234"
    assert_equal "http://example.test:1234", AIGit::Config.base_url
  end

  def test_request_format_for_each_provider
    ENV["AI_GIT_AI_PROVIDER"] = "jan"
    assert_equal :openai, AIGit::Config.request_format

    ENV["AI_GIT_AI_PROVIDER"] = "ollama"
    assert_equal :ollama, AIGit::Config.request_format
  end
end
