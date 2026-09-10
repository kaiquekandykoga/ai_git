# frozen_string_literal: true
# test/ai_git/test_help.rb
#
# @purpose      Cover the help command: the overview, the per-subcommand
#               topics, the flag aliases, and the unknown-topic error.
# @exports      Subject under test: AIGit::Commands::Help.
# @dependencies test/test_helper: loads the library and the test framework;
#               stringio: captures what the command prints.
# @sideEffects  Replaces $stdout within a block that restores it.
# @notes        Asserts that the overview names every routed subcommand and
#               that every topic is reachable, so a subcommand added to the
#               router without help text fails the suite.

require_relative "../test_helper"
require "stringio"

class TestHelp < Test::Unit::TestCase
  Help = AIGit::Commands::Help

  def with_captured_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def test_usage_lists_every_routed_subcommand
    out = with_captured_stdout { Help.call([]) }
    AIGit::SUBCOMMANDS.each_key { |name| assert_include out, name }
  end

  def test_every_routed_subcommand_has_a_topic
    AIGit::SUBCOMMANDS.each_key do |name|
      assert_include Help.topic(name), "Usage: ai_git #{name}"
    end
  end

  def test_commit_topic_documents_every_option_the_parser_accepts
    topic = Help.topic("commit")
    %w[-n --dry-run --no-push -y --yes -f --force -h --help].each do |flag|
      assert_include topic, flag
    end
  end

  def test_commit_topic_explains_the_confirmation_prompt
    assert_include Help.topic("commit"), AIGit::Prompt::QUESTION.strip
  end

  def test_config_topic_says_it_changes_nothing
    assert_include Help.topic("config"), "nothing is"
  end

  def test_help_topic_documents_the_argument
    assert_include Help.topic("help"), "ai_git help commit"
  end

  def test_help_flags_resolve_to_the_help_topic
    AIGit::HELP_FLAGS.each { |flag| assert_equal Help.topic("help"), Help.topic(flag) }
  end

  def test_unknown_topic_raises_and_names_the_known_ones
    error = assert_raises(RuntimeError) { Help.topic("nope") }
    assert_include error.message, "Unknown help topic: nope"
    assert_include error.message, "commit"
  end

  def test_call_prints_the_named_topic
    out = with_captured_stdout { Help.call(["commit"]) }
    assert_include out, "Usage: ai_git commit"
  end
end
