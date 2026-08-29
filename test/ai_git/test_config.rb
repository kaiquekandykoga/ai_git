# frozen_string_literal: true
# test/ai_git/test_config.rb
#
# @purpose      Cover the resolution of provider settings from the defaults and
#               from the YAML config file, including its validation.
# @exports      Subject under test: AIGit::Config.
# @dependencies test/test_helper: loads the library, the test framework, and
#               with_config_dir.
# @sideEffects  Points AIGit::Config at a temporary directory and drops the
#               memoized settings, both restored when each block ends.

require_relative "../test_helper"

class TestConfig < Test::Unit::TestCase
  def test_provider_is_llama_cpp
    assert_equal "llama_cpp", AIGit::Config.provider
  end

  def test_endpoint_is_openai_chat_completions
    assert_equal "/v1/chat/completions", AIGit::Config.endpoint
  end

  def test_defaults_apply_without_a_config_file
    with_config_dir(nil) do
      assert_nil AIGit::Config.config_path
      assert_equal({}, AIGit::Config.settings)
      assert_equal "ggml-org/gemma-4-E4B-it-GGUF:Q8_0", AIGit::Config.model_name
      assert_equal "http://127.0.0.1:8080", AIGit::Config.base_url
      assert_false AIGit::Config.no_color?
    end
  end

  def test_config_file_overrides_the_defaults
    with_config_dir("model_name: custom-model\nbase_url: http://example.test:1234\n") do |dir|
      assert_equal File.join(dir, "config.yml"), AIGit::Config.config_path
      assert_equal "custom-model", AIGit::Config.model_name
      assert_equal "http://example.test:1234", AIGit::Config.base_url
    end
  end

  def test_yaml_extension_is_also_read
    with_config_dir("model_name: yaml-model\n", filename: "config.yaml") do
      assert_equal "yaml-model", AIGit::Config.model_name
    end
  end

  def test_partial_config_keeps_the_other_defaults
    with_config_dir("base_url: https://models.example.test\n") do
      assert_equal "ggml-org/gemma-4-E4B-it-GGUF:Q8_0", AIGit::Config.model_name
      assert_equal "https://models.example.test", AIGit::Config.base_url
    end
  end

  def test_empty_config_file_uses_the_defaults
    with_config_dir("") do
      assert_equal({}, AIGit::Config.settings)
      assert_equal "http://127.0.0.1:8080", AIGit::Config.base_url
    end
  end

  def test_values_are_stripped
    with_config_dir("model_name: \"  spaced-model  \"\n") do
      assert_equal "spaced-model", AIGit::Config.model_name
    end
  end

  def test_no_color_accepts_boolean_and_string_truths
    ["no_color: true\n", "no_color: \"yes\"\n", "no_color: \"1\"\n", "no_color: \"On\"\n"].each do |contents|
      with_config_dir(contents) { assert_true AIGit::Config.no_color? }
    end
  end

  def test_no_color_is_false_when_unset_or_falsey
    ["", "no_color: false\n", "no_color: \"\"\n"].each do |contents|
      with_config_dir(contents) { assert_false AIGit::Config.no_color? }
    end
  end

  def test_settings_are_read_once_per_process
    with_config_dir("model_name: first-model\n") do |dir|
      assert_equal "first-model", AIGit::Config.model_name
      File.write(File.join(dir, "config.yml"), "model_name: second-model\n")
      assert_equal "first-model", AIGit::Config.model_name

      AIGit::Config.reset!
      assert_equal "second-model", AIGit::Config.model_name
    end
  end

  def test_malformed_yaml_raises
    with_config_dir("model_name: [unclosed\n") do
      error = assert_raises(RuntimeError) { AIGit::Config.model_name }
      assert_match(/Invalid YAML/, error.message)
    end
  end

  def test_non_mapping_config_raises
    with_config_dir("- model_name\n") do
      error = assert_raises(RuntimeError) { AIGit::Config.model_name }
      assert_match(/expected a mapping of settings/, error.message)
    end
  end

  def test_unknown_setting_raises_and_lists_the_known_keys
    with_config_dir("modelname: typo\n") do
      error = assert_raises(RuntimeError) { AIGit::Config.model_name }
      assert_match(/Unknown setting in /, error.message)
      assert_match(/modelname/, error.message)
      assert_match(/Known settings: model_name, base_url, no_color/, error.message)
    end
  end

  def test_non_string_value_raises
    ["model_name: 42\n", "base_url: []\n", "model_name: \"   \"\n"].each do |contents|
      with_config_dir(contents) do
        error = assert_raises(RuntimeError) { contents.start_with?("base_url") ? AIGit::Config.base_url : AIGit::Config.model_name }
        assert_match(/expected a non-empty string/, error.message)
      end
    end
  end

  def test_base_uri_rejects_a_non_http_url
    with_config_dir("base_url: ftp://example.test\n") do
      error = assert_raises(RuntimeError) { AIGit::Config.base_uri }
      assert_match(/Invalid base_url/, error.message)
    end
  end

  def test_loopback_and_remote_base_urls
    with_config_dir("base_url: http://localhost:8080\n") do
      assert_true AIGit::Config.loopback_base_url?
      assert_false AIGit::Config.insecure_remote_base_url?
    end

    with_config_dir("base_url: http://models.example.test\n") do
      assert_false AIGit::Config.loopback_base_url?
      assert_true AIGit::Config.insecure_remote_base_url?
    end
  end
end
