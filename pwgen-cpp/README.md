# pwgen-c++

A C++ translation of the Java PwGenCommand logic.

## Build
- Requires a C++17 compiler and make
- From repository root `pwgen-cpp` call `make all`

## Run
- From pwgen-cpp:  
  `./pwgen-cpp [number] [numberOfDigits] [delimiters] [-U|--wordsStartWithUppercase] [-L|--lang <de|en>] [-v|--verbose]`

# Behavior/Options
The behavior matches the Java implementation.
- `number`: number of words to combine (default 4)
- `numberOfDigits`: how many digits to insert at a random word position (default 3; 0 disables digits)
- `delimiters`: characters to randomly use between words (default "=/*-+")
- `-U` / --wordsStartWithUppercase: capitalize first character of each word
- `-L` / `--lang <code>`: language code (e.g. "de" or "en"). If omitted, attempts to infer from LANG env, else defaults to "en". With `-v`, prints the default language used.
- `-v` / `--verbose`: print diagnostic information to stderr

# Wordlists
- Copied from `pwgen-java/src/main/resources/wordlist_*.txt` into `pwgen-c++/wordlist_*.txt`

# Examples
- `./pwgen-cpp`
- `./pwgen-cpp -U -L de 5 2 "-_."`
- `./pwgen-cpp --lang en --wordsStartWithUppercase --verbose 6 0`
