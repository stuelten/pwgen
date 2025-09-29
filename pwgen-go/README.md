# pwgen-go

A Go implementation of the Java PwGenCommand logic.

## Build
- Requires Go 1.16+ (uses `embed` for wordlists)
- From repository root:
  - `cd pwgen-go && go build -o pwgen-go`
  - or directly: `go build -o pwgen-go ./pwgen-go`

## Run
- From pwgen-go directory (or with the compiled binary on your PATH):
  `./pwgen-go [number] [numberOfDigits] [delimiters] [-U|--wordsStartWithUppercase] [-L|--lang <de|en>] [-v|--verbose]`

# Behavior/Options
The behavior matches the Java implementation.
- `number`: number of words to combine (default 4)
- `numberOfDigits`: how many digits to insert at a random word position (default 3; 0 disables digits)
- `delimiters`: characters to randomly use between words (default "=/*-+")
- `-U` / `--wordsStartWithUppercase`: capitalize first character of each word
- `-L` / `--lang <code>`: language code (e.g. "de" or "en"). If omitted, attempts to infer from the `LANG` environment variable (e.g. `en_US.UTF-8` -> `en`); if not set, defaults to `en`.
- `-v` / `--verbose`: print diagnostic information to stderr (e.g., wordlist load details)

# Wordlists
- Embedded via Go's `embed` from `pwgen-go/assets/wordlist_*.txt`.
- The files originate from `pwgen-java/src/main/resources/wordlist_*.txt`.

# Examples
- `./pwgen-go`
- `./pwgen-go -U -L de 5 2 "-_."`
- `./pwgen-go --lang en --wordsStartWithUppercase --verbose 6 0`
