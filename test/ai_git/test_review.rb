# frozen_string_literal: true

require_relative "../test_helper"

class TestReview < Test::Unit::TestCase
  def test_review_module_exists
    assert_kind_of Module, AIGit::Review
  end

  def test_review_call_is_method
    assert_respond_to AIGit::Review, :call
  end
end
