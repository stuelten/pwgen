#!/bin/bash
# Use strict mode for Bash scripts:
# catch errors early and prevent silently ignoring failures.
set -euo pipefail

fail() {
  echo "Error: $*" >&2
  exit 1
}

# only these 3 languages are supported :)
for lang in de en fr; do
  echo "# Known language ${lang} must not produce errors"
  if ! ./pwgen-macos -L "${lang}" 3 3 '+' >/dev/null; then
    fail "Exit code > 0 for language ${lang}"
  fi

  # use '+' as delimiter between words
  output=$(./pwgen-macos -L "${lang}" 9 3 '+')
  [[ -n "$output" ]] || fail "No output for ${lang}"

  echo "# Check if all words are from correct wordlist"
  # Used '+' as delimiter above
  IFS='+' read -r -a tokens <<< "$output"
  for token in "${tokens[@]}"; do
    # remove digits
    word=${token//[0-9]/}
    [[ -z "$word" ]] && continue
    if ! grep -q -F "$word" "src/main/resources/wordlist_${lang}.txt"; then
      fail "$word not in wordlist for language $lang"
    fi
  done

done

echo "# Unknown language ZZ must produce errors"
if ./pwgen-macos -L ZZ 3 3 '+' >/dev/null 2>&1; then
  fail "Exit code == 0 for unknown language ZZ"
fi
output=$(./pwgen-macos -L ZZ 3 3 '+' || true)
[[ -z "$output" ]] || fail "Output for unknown language ZZ"
