#include "ai_git/ollama.h"
#include <curl/curl.h>
#include <cstring>
#include <sstream>
#include <stdexcept>
#include <string>

namespace ai_git {
namespace ollama {

namespace {

size_t write_callback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

std::string escape_json(const std::string& s) {
    std::ostringstream o;
    for (char c : s) {
        switch (c) {
            case '"': o << "\\\""; break;
            case '\\': o << "\\\\"; break;
            case '\n': o << "\\n"; break;
            case '\r': o << "\\r"; break;
            case '\t': o << "\\t"; break;
            default: o << c;
        }
    }
    return o.str();
}

} // namespace

std::string generate_commit_message(const std::string& diff) {
    if (diff.empty()) {
        throw std::runtime_error("No staged changes to generate commit message for");
    }

    CURL* curl = curl_easy_init();
    if (!curl) {
        throw std::runtime_error("Failed to initialize CURL");
    }

    std::string response;
    std::string prompt = R"(Generate a concise, descriptive commit message for these changes. "
"Output only the commit message, no prefix like 'feat:' or 'fix:', no explanations. "
"Keep it under 72 characters if possible. "
"Changes:
)" + diff;

    std::string json_body = R"({"model": "llama3.2:3b", "prompt": ")" + escape_json(prompt) + R"(", "stream": false})";

    curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:11434/api/generate");
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_body.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 120L);

    struct curl_slist* headers = nullptr;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    CURLcode res = curl_easy_perform(curl);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) {
        throw std::runtime_error("Failed to connect to Ollama. Is it running?");
    }

    std::string key = "\"response\":\"";
    size_t start = response.find(key);
    if (start == std::string::npos) {
        throw std::runtime_error("Invalid response from Ollama");
    }
    start += key.size();
    size_t end = response.find("\"}", start);
    if (end == std::string::npos) {
        end = response.find("\"", start);
    }
    std::string msg = response.substr(start, end - start);

    size_t pos;
    while ((pos = msg.find("\\n")) != std::string::npos) {
        msg.replace(pos, 2, "\n");
    }
    while ((pos = msg.find("\\\"")) != std::string::npos) {
        msg.replace(pos, 2, "\"");
    }

    if (!msg.empty() && msg.back() == '"') {
        msg.pop_back();
    }

    return msg;
}

} // namespace ollama
} // namespace ai_git