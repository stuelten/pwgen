#!/usr/bin/env python3
# Copyright 2025 Timo Stülten
# Licensed under the Apache License, Version 2.0

from __future__ import annotations

import argparse
import locale
import os
import random
import sys
from typing import List

try:
    from .wordlists import words_for_lang
    from . import __version__
except ImportError:  # Running as a script (no package parent)
    from pwgen_python.wordlists import words_for_lang
    from pwgen_python import __version__


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="pwgen", add_help=True)

    # Positional parameters with defaults, matching Java behavior
    parser.add_argument("number", nargs="?", type=int, default=4, help="Number of words to combine.")
    parser.add_argument(
        "numberOfDigits", nargs="?", type=int, default=3, help="Generate this number of digits."
    )
    parser.add_argument(
        "delimiters", nargs="?", default="=/*-+", help="Delimiters to use between words"
    )

    parser.add_argument(
        "-U", "--wordsStartWithUppercase", action="store_true", help="Set first character of each word to uppercase"
    )
    parser.add_argument(
        "-L", "--lang", default="", help="Language to use, e.g. 'de' or 'en'"
    )
    parser.add_argument("-v", "--verbose", action="store_true", default=False, help="be verbose.")
    parser.add_argument("-V", "--version", action="version", version=f"{__version__}")

    return parser.parse_args(argv)


def _delimiters_list(delimiters: str) -> List[str]:
    return [ch for ch in delimiters]


def _generate_digits(n: int) -> str:
    # Match Java: digits 0-9, length n
    return "".join(str(random.randint(0, 9)) for _ in range(n))


def _detect_default_language() -> str:
    """Detect the default language code without using deprecated locale.getdefaultlocale().

    Strategy:
    - Try locale.getlocale()[0]. This reflects the current LC_CTYPE setting.
    - Fallback to environment variables: LC_ALL, LC_CTYPE, LANG.
    - Ignore 'C' and 'POSIX'. Return lowercase two-letter language or 'en'.
    """
    lang: str | None = None

    try:
        loc = locale.getlocale()[0]
    except Exception:
        loc = None

    if loc and loc not in ("C", "POSIX"):
        lang = loc.split("_")[0].lower()

    if not lang:
        val = os.environ.get("LANG")
        if val:
            # Example: 'en_US.UTF-8' -> 'en_US'
            code = val.split(".")[0]
            if code and code not in ("C", "POSIX"):
                lang = code.split("_")[0].lower()

    return lang or "en"


def generate(word_list: List[str], number: int, delimiters: List[str], number_of_digits: int, uppercase: bool) -> str:
    if word_list is None:
        raise ValueError("word_list is required")
    if number < 0 or number > len(word_list):
        raise ValueError(f"number must be > 0 and <= {len(word_list)}! Actual: {number}")
    if not delimiters:
        raise ValueError("delimiters must not be empty")

    # Choose unique words (no duplicates), like the Java shuffle logic
    indices = random.sample(range(len(word_list)), k=number)

    parts: List[str] = []
    number_pos = random.randint(0, number - 1) if number_of_digits > 0 else -1

    for i, idx in enumerate(indices):
        word = word_list[idx]
        if uppercase and word:
            word = word[0].upper() + word[1:]
        parts.append(word)
        if number_of_digits > 0 and i == number_pos:
            parts.append(_generate_digits(number_of_digits))
        if i < number - 1:
            parts.append(random.choice(delimiters))

    return "".join(parts)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)

    lang_to_use = args.lang
    if not lang_to_use:
        lang_to_use = _detect_default_language()
        if args.verbose:
            print(f"Use default language: {lang_to_use}", file=sys.stderr)

    words = words_for_lang(lang_to_use, verbose=args.verbose)
    if words is None:
        print(f"ERROR: Cannot read wordlist for language {lang_to_use}", file=sys.stderr)
        return 1

    try:
        result = generate(
            words,
            args.number,
            _delimiters_list(args.delimiters),
            args.numberOfDigits,
            args.wordsStartWithUppercase,
        )
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
