# pwgen-python

Pure Python implementation of pwgen.
Generates passwords from common word lists with optional digits and delimiters.

## Usage

```
Usage: pwgen [-hUvV] [-L=<lang>] [<number>] [<numberOfDigits>] [<delimiters>]

  <number>                          Number of words to combine. Default: 4
  <numberOfDigits>                  Generate this number of digits. Default: 3
  <delimiters>                      Delimiters to use between words. Default: =/*-+
  -h, --help                        Show help.
  -L, --lang <lang>                 Language to use, e.g. 'de', 'en', 'fr'. 
                                    Default: locale language
  -U, --wordsStartWithUppercase     Set first character of each word to uppercase
  -v, --verbose                     Be verbose
  -V, --version                     Print version information and exit
```

## Build and Install

Build (standard Python):
1. `python -m build`

Install locally and run:
1. `pip install dist/pwgen_python-*.whl`
2. `pwgen -U -L de 4`

Create a native binary with PyInstaller:
1. `pip install pyinstaller`
2. `pyinstaller --onefile --name pwgen-python src/pwgen_python/cli.py`

The produced binary (`dist/pwgen-python`) contains the embedded wordlists.
