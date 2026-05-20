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

  def test_provider_accepts_claude_grok_llama_cpp_unsloth
    %w[claude grok llama_cpp unsloth].each do |name|
      ENV["AI_GIT_AI_PROVIDER"] = name
      assert_equal name, AIGit::Config.provider
    end
  end

  def test_provider_rejects_unknown
    ENV["AI_GIT_AI_PROVIDER"] = "bogus"
    assert_raises(RuntimeError) { AIGit::Config.provider }
  end

  def test_model_name_falls_back_to_provider_default
    assert_equal "Jan-v3.5-4B-Q4_K_XL", AIGit::Config.model_name
  end

  def test_model_name_default_per_provider
    {
      "ollama" => "gemma4:e4b",
      "claude" => "claude-opus-4-7",
      "grok" => "grok-4",
      "llama_cpp" => "default",
      "unsloth" => "unsloth/gemma-3-4b-it"
    }.each do |provider, model|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_equal model, AIGit::Config.model_name
    end
  end

  def test_model_name_uses_env_override
    ENV["AI_GIT_MODEL_NAME"] = "custom-model"
    assert_equal "custom-model", AIGit::Config.model_name
  end

  def test_base_url_default_per_provider
    {
      "jan" => "http://127.0.0.1:1337",
      "ollama" => "http://localhost:11434",
      "claude" => "https://api.anthropic.com",
      "grok" => "https://api.x.ai",
      "llama_cpp" => "http://127.0.0.1:8080",
      "unsloth" => "http://127.0.0.1:8000"
    }.each do |provider, url|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_equal url, AIGit::Config.base_url
    end
  end

  def test_base_url_uses_env_override
    ENV["AI_GIT_BASE_URL"] = "http://example.test:1234"
    assert_equal "http://example.test:1234", AIGit::Config.base_url
  end

  def test_request_format_for_each_provider
    {
      "jan" => :openai,
      "ollama" => :ollama,
      "claude" => :anthropic,
      "grok" => :openai,
      "llama_cpp" => :openai,
      "unsloth" => :openai
    }.each do |provider, format|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_equal format, AIGit::Config.request_format
    end
  end
end
