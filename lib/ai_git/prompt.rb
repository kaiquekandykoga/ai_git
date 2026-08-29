# frozen_string_literal: true
# lib/ai_git/prompt.rb
#
# @purpose      Own the interactive confirmation step: ask what to do with the
#               generated message, and open the user's editor on request.
# @exports      AIGit::Prompt: ACTIONS, QUESTION, .interactive?, .ask_action,
#               .edit.
# @dependencies ai_git/ui: bolds the question before it is printed;
#               shellwords: splits $VISUAL or $EDITOR into command and args;
#               tempfile: holds the message the editor opens.
# @sideEffects  Reads stdin and writes to stdout; spawns the editor process;
#               writes a tempfile; reads $VISUAL and $EDITOR.
# @notes        A closed stdin, where gets returns nil, is treated as an abort
#               so a piped run never blocks waiting on an answer.

require "shellwords"
require "tempfile"

require_relative "ui"

module AIGit
  module Prompt
    module_function

    ACTIONS = {
      "" => :accept, "a" => :accept, "accept" => :accept, "y" => :accept, "yes" => :accept,
      "e" => :edit, "edit" => :edit,
      "r" => :regenerate, "regen" => :regenerate, "regenerate" => :regenerate,
      "q" => :abort, "quit" => :abort, "n" => :abort, "no" => :abort, "abort" => :abort
    }.freeze

    QUESTION = "Commit this message? [A]ccept / [e]dit / [r]egenerate / [q]uit: "

    def interactive?
      $stdin.tty? && $stdout.tty?
    end

    def ask_action
      loop do
        $stdout.print AIGit::UI.bold(QUESTION)
        $stdout.flush

        answer = $stdin.gets
        return :abort if answer.nil?

        action = ACTIONS[answer.strip.downcase]
        return action if action

        AIGit::UI.info("Please answer a, e, r or q.")
      end
    end

    def edit(message)
      editor = ENV["VISUAL"] || ENV["EDITOR"]
      raise "Cannot edit: set $EDITOR or $VISUAL first." if editor.to_s.strip.empty?

      Tempfile.create(["ai_git_commit_msg", ".txt"]) do |file|
        file.write(message)
        file.flush

        raise "Editor #{editor} exited with an error." unless system(*Shellwords.split(editor), file.path)

        File.read(file.path)
      end
    end
  end
end
