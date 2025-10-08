# Embedded wordlists are packaged as data files within this module and loaded at runtime.
from __future__ import annotations

from typing import List
import importlib.resources as pkg_resources
import sys


def _camelize_blanks(s: str) -> str:
    s = s.strip()
    while " " in s:
        pos = s.index(" ")
        if pos + 1 < len(s):
            uppercase = s[pos + 1].upper()
            s = s[:pos] + uppercase + s[pos + 2:]
        s = s.strip()
    return s


def _to_list(blob: str) -> List[str]:
    words: List[str] = []
    for line in blob.splitlines():
        line = line.strip()
        if not line:
            continue
        words.append(_camelize_blanks(line))
    return words


_WORDS_CACHE = {}


def _read_asset(lang: str, verbose: bool) -> str | None:
    filename = f"wordlist_{lang}.txt"
    try:
        data = pkg_resources.read_text(__package__ + ".assets", filename, encoding="utf-8")
        return data
    except Exception as e:
        if verbose:
            print(f"Cannot read wordlist: {filename} ({e})", file=sys.stderr)
        return None


def words_for_lang(lang: str, verbose: bool = False) -> List[str] | None:
    lang = (lang or "").strip().lower()
    if not lang:
        return None
    if lang in _WORDS_CACHE:
        return _WORDS_CACHE[lang]
    if lang not in ("en", "fr", "de"):
        if verbose:
            print(f"Unknown language: {lang}", file=sys.stderr)
        return None
    text = _read_asset(lang, verbose)
    if text is None:
        return None
    words = _to_list(text)
    _WORDS_CACHE[lang] = words
    return words
