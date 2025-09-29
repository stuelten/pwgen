pwgen-c++

A C++ translation of the Java PwGenCommand logic.

Build
- Requires CMake (>=3.15) and a C++17 compiler
- From repository root:
  - mkdir -p pwgen-c++/build
  - cd pwgen-c++/build
  - cmake ..
  - cmake --build . --config Release

Run
- From pwgen-c++ or any directory that has the wordlist files available:
  - ./pwgen-cpp [number] [numberOfDigits] [delimiters] [-U|--wordsStartWithUppercase] [-L|--lang <de|en>] [-v|--verbose]

Behavior (matches Java PwGenCommand)
- number: number of words to combine (default 4)
- numberOfDigits: how many digits to insert at a random word position (default 3; 0 disables digits)
- delimiters: characters to randomly use between words (default "=/*-+")
- -U / --wordsStartWithUppercase: capitalize first character of each word
- -L / --lang <code>: language code (e.g. "de" or "en"). If omitted, attempts to infer from LANG env, else defaults to "en". With -v, prints the default language used.
- -v / --verbose: print diagnostic information to stderr

Wordlists
- Copied from pwgen-java/src/main/resources into pwgen-c++/wordlist_de.txt and pwgen-c++/wordlist_en.txt
- The executable searches for wordlist_<lang>.txt in:
  1. current working directory
  2. pwgen-c++/ subfolder of current working directory
  3. the executable directory

Examples
- ./pwgen-cpp
- ./pwgen-cpp 5 2 "-_." -U -L de
- ./pwgen-cpp 6 0 --lang en --wordsStartWithUppercase --verbose
