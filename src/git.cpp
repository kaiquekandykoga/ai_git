#include "ai_git/git.h"
#include <array>
#include <cstdlib>
#include <memory>
#include <stdexcept>

namespace ai_git {
namespace git {

namespace {

std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen failed");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

} // namespace

std::string get_staged_files() {
    return exec("git diff --cached --name-only");
}

std::string get_diff() {
    return exec("git diff --cached");
}

std::string get_current_branch() {
    std::string result = exec("git rev-parse --abbrev-ref HEAD");
    if (!result.empty() && result.back() == '\n') {
        result.pop_back();
    }
    return result;
}

void run_command(const std::string& cmd, const std::string& args) {
    std::string full_cmd = cmd + " " + args;
    int status = system(full_cmd.c_str());
    if (status != 0) {
        throw std::runtime_error("Command failed: " + full_cmd);
    }
}

} // namespace git
} // namespace ai_git