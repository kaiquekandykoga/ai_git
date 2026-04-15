#include "ai_git/git.h"
#include "ai_git/ollama.h"
#include <iostream>
#include <string>

int main() {
    try {
        std::string staged = ai_git::git::get_staged_files();
        if (staged.empty()) {
            std::cerr << "Error: No staged files. Use 'git add' first." << std::endl;
            return 1;
        }

        std::string diff = ai_git::git::get_diff();
        std::string branch = ai_git::git::get_current_branch();

        std::cout << "Staged files:\n" << staged << std::endl;
        std::cout << "Branch: " << branch << std::endl;
        std::cout << "Generating commit message..." << std::endl;

        std::string message = ai_git::ollama::generate_commit_message(diff);

        std::cout << "Commit message: " << message << std::endl;

        std::string escaped_msg = "\"" + message + "\"";
        ai_git::git::run_command("git", "commit -m " + escaped_msg);
        std::cout << "Committed." << std::endl;

        ai_git::git::run_command("git", "push");
        std::cout << "Pushed." << std::endl;

        return 0;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}