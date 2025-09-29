#pragma once
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>
#include <cctype>

namespace embedded_wordlists {

// Helper to trim and camelize spaces like main implementation
static inline std::string trim(const std::string &s) {
    size_t start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    size_t end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}
static inline std::string camelizeSpaces(std::string s) {
    s = trim(s);
    while (true) {
        auto pos = s.find(' ');
        if (pos == std::string::npos) break;
        if (pos + 1 < s.size()) {
            char upper = static_cast<char>(std::toupper(static_cast<unsigned char>(s[pos + 1])));
            s = s.substr(0, pos) + upper + s.substr(pos + 2);
        } else {
            s.erase(pos, 1);
        }
        s = trim(s);
    }
    return s;
}

// Auto-generated raw wordlists are included from this header (created by Makefile)
#include "generated_wordlists_data.hpp"

static inline std::vector<std::string> splitLines(const char *data) {
    std::vector<std::string> out;
    std::istringstream iss(data);
    std::string line;
    while (std::getline(iss, line)) {
        auto w = camelizeSpaces(line);
        if (!w.empty()) out.push_back(w);
    }
    return out;
}

static inline const char* selectRaw(const std::string &lang) {
    std::string l = lang;
    std::transform(l.begin(), l.end(), l.begin(), [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
    if (l == "fr") return WORDS_FR;
    if (l == "de") return WORDS_DE;
    return WORDS_EN; // default
}

static inline std::vector<std::string> get(const std::string &lang) {
    return splitLines(selectRaw(lang));
}

} // namespace embedded_wordlists
