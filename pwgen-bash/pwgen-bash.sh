#!/usr/bin/env bash
set -euo pipefail

# pwgen-bash — Bash translation of pwgen-java PwGenCommand
# Usage mirrors pwgen-java:
#   pwgen-bash [-hUvV] [-L=<lang>] [<number>] [<numberOfDigits>] [<delimiters>]
# Defaults:
#   number=4, numberOfDigits=3, delimiters==/*-+
# Options:
#   -h, --help                       Show this help message and exit.
#   -L, --lang=<lang>                Language to use, e.g. 'de' or 'en'
#   -U, --wordsStartWithUppercase    Set first character of each word to uppercase
#   -v, --verbose                    be verbose
#   -V, --version                    Print version information and exit.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Allow overriding the wordlist directory via environment variable for bundled builds
WORDLIST_DIR="${PWGEN_WORDLISTS_DIR:-${SCRIPT_DIR}/wordlists}"

# Defaults
NUMBER=4
NUMBER_OF_DIGITS=3
DELIMITERS='=/*-+'
WORDS_UPPERCASE=false
LANGUAGE=""
VERBOSE=false

VERSION=1.0.0

print_version() {
  echo "$VERSION"
}

print_help() {
  cat <<'EOF'
Usage: pwgen [-hUvV] [-L=<lang>] [<number>] [<numberOfDigits>] [<delimiters>]

[number]                        Number of words to combine.
[numberOfDigits]                Generate this number of digits.
[delimiters]                    Delimiters to use between words
-h, --help                      Show this help message and exit.
-L, --lang=<lang>               Language to use, e.g. 'de' or 'en'
-U, --wordsStartWithUppercase   Set first character of each word to uppercase
-v, --verbose                   be verbose.
-V, --version                   Print version information and exit.
EOF
}

# Get a random between 0 and $1.
#
# Use $RANDOM (0..32767) and scale to [0, $1).
# For the small ranges (word count, delimiter count), using modulo is good enough.
rand_int() { # args: max_exclusive
  local max=$1
  echo $(( RANDOM % max ))
}

# Choose k unique indices from 0..n-1
# We need to pick unique words without repetition. Bash has no built-in set type,
# so we emulate a set with an associative array `seen` (keys are indices).
# We keep picking random candidates until `k` unique ones are collected.
# The result is printed line by line and captured by command substitution into an array.
choose_unique_indices() {
  local k=$1 n=$2
  local -a chosen=()
  local -A seen=()
  while [[ ${#chosen[@]} -lt $k ]]; do
    local c
    c=$(rand_int "$n")
    if [[ -z "${seen[$c]:-}" ]]; then
      seen[$c]=1
      chosen+=(${c})
    fi
  done
  printf '%s\n' "${chosen[@]}"
}

# Generate a string consisting of $1 random digits [0-9].
# Uses $RANDOM modulo 10 to produce each digit. Again, good enough.
generate_digits() {
  local count=$1
  local out=""
  for ((j=0;j<count;j++)); do
    out+=$(( RANDOM % 10 ))
  done
  printf '%s' "$out"
}


# Simple option parser supporting short and long options
POSITIONALS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -V|--version)
      print_version
      exit 0
      ;;
    -U|--wordsStartWithUppercase)
      WORDS_UPPERCASE=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -L|--lang)
      if [[ "$1" == *=* ]]; then
        LANGUAGE="${1#*=}"
        shift
      else
        shift
        LANGUAGE="${1:-}"
        if [[ -z "${LANGUAGE}" ]]; then
          echo "ERROR: --lang requires an argument" >&2
          exit 2
        fi
        shift
      fi
      ;;
    --lang=*)
      LANGUAGE="${1#*=}"
      shift
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "ERROR: Unknown option: $1" >&2
      exit 2
      ;;
    *)
      POSITIONALS+=("$1")
      shift
      ;;
  esac
done

# Remaining args as positionals
if [[ ${#POSITIONALS[@]} -ge 1 ]]; then
  NUMBER="${POSITIONALS[0]}"
fi
if [[ ${#POSITIONALS[@]} -ge 2 ]]; then
  NUMBER_OF_DIGITS="${POSITIONALS[1]}"
fi
if [[ ${#POSITIONALS[@]} -ge 3 ]]; then
  DELIMITERS="${POSITIONALS[2]}"
fi
if [[ ${#POSITIONALS[@]} -gt 3 ]]; then
  echo "ERROR: Too many arguments" >&2
  exit 2
fi

# Validate numeric inputs
if ! [[ "$NUMBER" =~ ^[0-9]+$ ]] || [[ "$NUMBER" -le 0 ]]; then
  echo "ERROR: <number> must be a positive integer" >&2
  exit 2
fi
if ! [[ "$NUMBER_OF_DIGITS" =~ ^[0-9]+$ ]]; then
  echo "ERROR: <numberOfDigits> must be a non-negative integer" >&2
  exit 2
fi

# Determine language if non was given
if [[ -z "${LANGUAGE}" ]]; then
  # Derive language from locale-related environment variables
  local_env="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  # Strip optional surrounding quotes and extract part before '_' or '.' (e.g., en_US.UTF-8 -> en)
  local_env=$(echo "${local_env}" | sed 's/^"\(.*\)"$/\1/' | cut -d'_' -f1 | cut -d'.' -f1)

  LANGUAGE="${local_env}"
  if [[ -z "${LANGUAGE}" ]]; then
    echo "ERROR: Could not determine language. Set it with --lang" >&2
    exit 2
  fi
  if $VERBOSE; then
    echo "Use language: ${LANGUAGE}" >&2
  fi
fi

# Search wordlist for $LANGUAGE
WORDLIST_FILE="${WORDLIST_DIR}/wordlist_${LANGUAGE}.txt"
if [[ ! -f "${WORDLIST_FILE}" ]]; then
  echo "ERROR: Cannot read wordlist for language ${LANGUAGE}" >&2
  exit 1
fi

# Read the word list into an array
# - Trim leading/trailing whitespace.
# - Skip empty lines.
# - Convert multi-word entries to CamelCase by removing spaces and uppercasing
#   the first character of each subsequent token: "foo bar" -> "fooBar".
# - Strip trailing CR (for Windows-formatted files).
WORDS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Strip trailing CR
  line=${line%$'\r'}
  # Trim leading whitespace (spaces and tabs)
  line="${line#"${line%%[!$' \t']*}"}"
  # Trim trailing whitespace (spaces and tabs)
  line="${line%"${line##*[!$' \t']}"}"
  # After trimming, skip empty
  [[ -z "$line" ]] && continue
  # Split into tokens by IFS (spaces/tabs collapse)
  IFS=$' \t' read -r -a parts <<< "$line"
  if (( ${#parts[@]} == 0 )); then
    continue
  fi
  word_part="${parts[0]}"
  for ((pi=1; pi<${#parts[@]}; pi++)); do
    part=${parts[pi]}
    # Uppercase first char of subsequent tokens without external tools
    first_char=${part:0:1}
    rest_part=${part:1}
    declare -u upfirst="$first_char"
    word_part+="${upfirst}${rest_part}"
  done
  WORDS+=("$word_part")
done < "${WORDLIST_FILE}"

# Do we now have words in WORDS?
if [[ ${#WORDS[@]} -eq 0 ]]; then
  echo "ERROR: Wordlist is empty: ${WORDLIST_FILE}" >&2
  exit 1
fi

# We must use fewer words than entries in the WORDS array
if [[ "$NUMBER" -gt ${#WORDS[@]} ]]; then
  echo "ERROR: number must be > 0 and <= ${#WORDS[@]}! Actual: ${NUMBER}" >&2
  exit 1
fi

# Build delimiter characters array from the commandline option.
# Split into single-character entries using Bash substring slicing.
# Example: "=/*-+" -> ["=", "/", "*", "-", "+"]
DELIM_CHARS=()
for ((di=0; di<${#DELIMITERS}; di++)); do
  DELIM_CHARS+=("${DELIMITERS:di:1}")
done

# Construct password

# Choose the position (0..NUMBER-1) at which to insert the random digit block relative to words.
NUMBER_POS=$(rand_int "$NUMBER")

# Capture the chosen unique word indices into a Bash array. The function prints
# one index per line; command substitution and word splitting turn that into an array.
indices=( $(choose_unique_indices "$NUMBER" "${#WORDS[@]}") )

# used to collect the result
out=""

for ((i=0;i<NUMBER;i++)); do
  # random index for word to use
  idx=${indices[$i]}
  # word to use
  word=${WORDS[$idx]}

  if $WORDS_UPPERCASE; then
    # Uppercase only the first character of the word without external tools
    first=${word:0:1}
    rest=${word:1}
    declare -u upfirst="$first"
    word="${upfirst}${rest}"
  fi
  out+="$word"
  # Insert the random digit block immediately after the word at NUMBER_POS
  # (if a positive digit count was requested).
  if [[ "$NUMBER_OF_DIGITS" -gt 0 && "$i" -eq "$NUMBER_POS" ]]; then
    out+="$(generate_digits "$NUMBER_OF_DIGITS")"
  fi
  # Last word? Then no delimiter
  if [[ $i -lt $((NUMBER-1)) ]]; then
    # Add a random delimiter behind word
    dindex=$(rand_int "${#DELIM_CHARS[@]}")
    out+="${DELIM_CHARS[$dindex]}"
  fi
done

printf '%s\n' "$out"
