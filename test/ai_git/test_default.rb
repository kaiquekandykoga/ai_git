# frozen_string_literal: true

require_relative "../test_helper"

class TestDefault < Test::Unit::TestCase
  def test_default_module_exists
    assert_kind_of Module, AIGit::Default
  end

  def test_default_call_is_method
    assert_respond_to AIGit::Default, :call
  end
end
