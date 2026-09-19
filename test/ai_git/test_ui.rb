# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class TestUI < Test::Unit::TestCase
  class FakeTTY < StringIO
    def tty?
      true
    end
  end

  def setup
    @original_stdout = $stdout
  end

  def teardown
    $stdout = @original_stdout
  end

  def test_paint_adds_ansi_codes_for_a_terminal
    $stdout = FakeTTY.new
    assert_equal "\e[1mhi\e[0m", AIGit::UI.paint("hi", :bold)
  end

  def test_paint_is_plain_when_not_a_terminal
    $stdout = StringIO.new
    assert_equal "hi", AIGit::UI.paint("hi", :bold)
  end

  def test_paint_respects_no_color
    $stdout = FakeTTY.new
    with_settings("no_color" => true) do
      assert_equal "hi", AIGit::UI.paint("hi", :bold)
    end
  end

  def test_paint_is_plain_when_the_config_cannot_be_read
    $stdout = FakeTTY.new
    with_stub(AIGit::Config, :settings, -> { raise "broken config" }) do
      assert_equal "hi", AIGit::UI.paint("hi", :bold)
    end
  end

  def test_paint_with_no_styles_is_plain
    $stdout = FakeTTY.new
    assert_equal "hi", AIGit::UI.paint("hi")
  end

  def test_color_predicate
    $stdout = FakeTTY.new
    assert_true AIGit::UI.color?
    $stdout = StringIO.new
    assert_false AIGit::UI.color?
  end

  def test_kv_prints_key_and_value
    $stdout = StringIO.new
    AIGit::UI.kv("Provider", "llama_cpp")
    assert_equal "Provider: llama_cpp\n", $stdout.string
  end
end
