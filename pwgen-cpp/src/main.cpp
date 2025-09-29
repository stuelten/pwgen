#include <algorithm>
#include <cctype>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <locale>
#include <random>
#include <set>
#include <sstream>
#include <string>
#include <unordered_set>
#include <vector>
// C stuff for getenv and strlen
#include <cstdlib>
#include <cstring>
#include "embedded_wordlists.hpp"

struct Options {
    int number = 4; // Number of words to combine
    int numberOfDigits = 3; // Number of digits to generate
    std::string delimiters = "=/*-+"; // Delimiters to use between words
    bool wordsStartWithUppercase = false; // Set first character of each word to uppercase
    std::string lang; // Language to use, e.g. 'de' or 'en'
    bool verbose = false; // be verbose
};

static std::vector<std::string> splitDelimiters(const std::string &delims) {
    std::vector<std::string> ret;
    ret.reserve(delims.size());
    for (char c : delims) ret.emplace_back(1, c);
    return ret;
}

static std::string generateDigits(std::mt19937_64 &rng, int numberOfDigits) {
    std::uniform_int_distribution<int> dist10(0, 9);
    std::string ret;
    ret.reserve(numberOfDigits);
    for (int j = 0; j < numberOfDigits; ++j) {
        ret.push_back(static_cast<char>('0' + dist10(rng)));
    }
    return ret;
}

static std::string generate(std::mt19937_64 &rng, const std::vector<std::string> &wordList,
                            int number, const std::vector<std::string> &delimiters,
                            int numberOfDigits, bool wordsStartWithUppercase) {
    if (wordList.empty()) {
        throw std::runtime_error("wordList must not be empty");
    }
    if (number <= 0 || number > static_cast<int>(wordList.size())) {
        std::ostringstream oss;
        oss << "number must be > 0 and <= " << wordList.size() << "! Actual: " << number;
        throw std::invalid_argument(oss.str());
    }

    // Create unique random indices
    std::uniform_int_distribution<size_t> distIndex(0, wordList.size() - 1);
    std::vector<size_t> shuffle;
    shuffle.reserve(number);
    std::unordered_set<size_t> used;
    while (shuffle.size() < static_cast<size_t>(number)) {
        size_t cand = distIndex(rng);
        if (used.insert(cand).second) shuffle.push_back(cand);
    }

    bool generateNumbers = numberOfDigits > 0;
    std::uniform_int_distribution<int> distNumberPos(0, number - 1);
    int numberPos = distNumberPos(rng);

    std::uniform_int_distribution<size_t> distDelim(0, delimiters.empty() ? 0 : delimiters.size() - 1);

    std::string ret;
    for (int i = 0; i < number; ++i) {
        std::string word = wordList[shuffle[i]];
        if (wordsStartWithUppercase && !word.empty()) {
            word[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(word[0])));
        }
        ret += word;
        if (generateNumbers && numberPos == i) {
            ret += generateDigits(rng, numberOfDigits);
        }
        if (i < number - 1 && !delimiters.empty()) {
            ret += delimiters[distDelim(rng)];
        }
    }
    return ret;
}

static Options parseArgs(int argc, char **argv) {
    Options opt;

    // Collect positional args that are not options
    std::vector<std::string> positional;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-U" || arg == "--wordsStartWithUppercase") {
            opt.wordsStartWithUppercase = true;
        } else if (arg == "-v" || arg == "--verbose") {
            opt.verbose = true;
        } else if (arg == "-L" || arg == "--lang") {
            if (i + 1 >= argc) {
                std::cerr << "ERROR: Missing value for " << arg << "\n";
                std::exit(1);
            }
            opt.lang = argv[++i];
        } else if (!arg.empty() && arg[0] == '-') {
            std::cerr << "Unknown option: " << arg << "\n";
            std::exit(1);
        } else {
            positional.push_back(arg);
        }
    }

    // Positional: number, numberOfDigits, delimiters
    if (!positional.empty()) {
        opt.number = std::stoi(positional[0]);
    }
    if (positional.size() > 1) {
        opt.numberOfDigits = std::stoi(positional[1]);
    }
    if (positional.size() > 2) {
        opt.delimiters = positional[2];
    }

    return opt;
}

int main(int argc, char **argv) {
    try {
        Options opt = parseArgs(argc, argv);

        std::string langToUse = opt.lang;
        if (langToUse.empty()) {
            try {
                // Obtain default locale language code similar to Java Locale.getDefault().getLanguage()
#if defined(__APPLE__) || defined(__linux__) || defined(__unix__)
                std::locale loc("");
#else
                std::locale loc("");
#endif
                // There's no direct method; we'll just default to "en" if not provided
                // because extracting just the language from C++ locale is non-trivial and system-dependent.
                // To preserve behavior, we try environment variables as a heuristic.
                const char *langEnv = std::getenv("LANG");
                if (langEnv && std::strlen(langEnv) >= 2) {
                    langToUse.assign(langEnv, langEnv + 2);
                } else {
                    langToUse = "en";
                }
            } catch (...) {
                langToUse = "en";
            }
            if (opt.verbose) {
                std::cerr << "Use default language: " << langToUse << "\n";
            }
        }

        // Use embedded wordlists only; do not read from filesystem
        std::vector<std::string> wordList = embedded_wordlists::get(langToUse);
        if (wordList.empty()) {
            // Fallback to English if requested language not available
            wordList = embedded_wordlists::get("en");
        }
        if (wordList.empty()) {
            std::cerr << "ERROR: No embedded wordlist available" << "\n";
            return 1;
        }

        // Seed RNG
        std::random_device rd;
        std::mt19937_64 rng(rd());

        std::string out = generate(rng, wordList, opt.number, splitDelimiters(opt.delimiters), opt.numberOfDigits, opt.wordsStartWithUppercase);
        std::cout << out << "\n";
        return 0;
    } catch (const std::exception &e) {
        std::cerr << "ERROR: " << e.what() << "\n";
        return 1;
    }
}
