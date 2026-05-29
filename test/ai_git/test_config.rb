# frozen_string_literal: true

require_relative "../test_helper"

class TestConfig < Test::Unit::TestCase
  def setup
    @original_env = {
      "AI_GIT_AI_PROVIDER" => ENV["AI_GIT_AI_PROVIDER"],
      "AI_GIT_MODEL_NAME" => ENV["AI_GIT_MODEL_NAME"],
      "AI_GIT_BASE_URL" => ENV["AI_GIT_BASE_URL"],
      "AI_GIT_API_KEY" => ENV["AI_GIT_API_KEY"],
      "ANTHROPIC_API_KEY" => ENV["ANTHROPIC_API_KEY"],
      "AZURE_OPENAI_API_KEY" => ENV["AZURE_OPENAI_API_KEY"]
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

  def test_provider_accepts_all_known_providers
    %w[claude grok llama_cpp unsloth mlx azure openrouter mistral gemini hugging_face nvidia_nim].each do |name|
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
      "unsloth" => "unsloth/gemma-3-4b-it",
      "mlx" => "mlx-community/Llama-3.2-3B-Instruct-4bit",
      "azure" => "gpt-4o-mini",
      "openrouter" => "openai/gpt-4o-mini",
      "mistral" => "mistral-large-latest",
      "gemini" => "gemini-2.0-flash",
      "hugging_face" => "meta-llama/Llama-3.3-70B-Instruct",
      "nvidia_nim" => "meta/llama-3.3-70b-instruct"
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
      "unsloth" => "http://127.0.0.1:8000",
      "mlx" => "http://127.0.0.1:8080",
      "azure" => "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT",
      "openrouter" => "https://openrouter.ai/api",
      "mistral" => "https://api.mistral.ai",
      "gemini" => "https://generativelanguage.googleapis.com",
      "hugging_face" => "https://router.huggingface.co",
      "nvidia_nim" => "https://integrate.api.nvidia.com"
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
      "unsloth" => :openai,
      "mlx" => :openai,
      "azure" => :azure,
      "openrouter" => :openai,
      "mistral" => :openai,
      "gemini" => :openai,
      "hugging_face" => :openai,
      "nvidia_nim" => :openai
    }.each do |provider, format|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_equal format, AIGit::Config.request_format
    end
  end

  def test_api_key_not_required_for_local_providers
    %w[jan ollama llama_cpp unsloth mlx].each do |provider|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_false AIGit::Config.api_key_required?, "#{provider} should not require a key"
    end
  end

  def test_api_key_required_for_hosted_providers
    %w[claude grok azure openrouter mistral gemini hugging_face nvidia_nim].each do |provider|
      ENV["AI_GIT_AI_PROVIDER"] = provider
      assert_true AIGit::Config.api_key_required?, "#{provider} should require a key"
    end
  end

  def test_api_key_prefers_generic_env
    ENV["AI_GIT_AI_PROVIDER"] = "claude"
    ENV["AI_GIT_API_KEY"] = "generic"
    ENV["ANTHROPIC_API_KEY"] = "specific"
    assert_equal "generic", AIGit::Config.api_key
  end

  def test_api_key_falls_back_to_anthropic_for_claude
    ENV["AI_GIT_AI_PROVIDER"] = "claude"
    ENV["ANTHROPIC_API_KEY"] = "anthropic-key"
    assert_equal "anthropic-key", AIGit::Config.api_key
  end

  def test_api_key_falls_back_to_azure_env_for_azure
    ENV["AI_GIT_AI_PROVIDER"] = "azure"
    ENV["AZURE_OPENAI_API_KEY"] = "azure-key"
    assert_equal "azure-key", AIGit::Config.api_key
  end

  def test_api_key_has_no_cross_provider_fallback
    ENV["AI_GIT_AI_PROVIDER"] = "grok"
    ENV["ANTHROPIC_API_KEY"] = "anthropic-key"
    assert_nil AIGit::Config.api_key
  end

  def test_api_key_nil_when_unset
    ENV["AI_GIT_AI_PROVIDER"] = "claude"
    assert_nil AIGit::Config.api_key
  end
end
