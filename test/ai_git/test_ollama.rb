require_relative '../test_helper'

class TestAIGitOllama < Test::Unit::TestCase
  def test_escape_json_handles_backslash
    input = 'path\\to\\file'
    assert_equal input, AIGit::Ollama.escape_json(input)
  end

  def test_escape_json_handles_double_quote
    input = 'say "hello"'
    expected = 'say \"hello\"'
    assert_equal expected, AIGit::Ollama.escape_json(input)
  end

  def test_escape_json_handles_newline
    input = "line1\nline2"
    expected = 'line1\\nline2'
    assert_equal expected, AIGit::Ollama.escape_json(input)
  end

  def test_escape_json_handles_carriage_return
    input = "line1\rline2"
    expected = 'line1\\rline2'
    assert_equal expected, AIGit::Ollama.escape_json(input)
  end

  def test_escape_json_handles_tab
    input = "col1\tcol2"
    expected = 'col1\\tcol2'
    assert_equal expected, AIGit::Ollama.escape_json(input)
  end
end
