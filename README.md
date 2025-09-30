# pwgen Project

Creates passwords
which are easy enough to be remembered
(or transferred via audio/telephone)
while being secure enough for usage.

The base idea is stolen from xkcd.com: https://preshing.com/20110811/xkcd-password-generator/.

The implementation is available in multiple languages:
- Java
- C++
- Go
- Rust

This way we are able to make some simple comparisons for the different implementations.
The performance of the different implementations must be taken with a grain of salt:
No implementation is optimized for speed.

## Command Line Options

All implemented applications supports the following command line options:

```
Usage: pwgen-* [-hUvV] [-L=<lang>] [<number>] [<numberOfDigits>] [<delimiters>]
[<number>]           Number of words to combine.
[<numberOfDigits>]   Generate this number of digits.
[<delimiters>]       Delimiters to use between words
-h, --help               Show this help message and exit.
-L, --lang=<lang>        Language to use, e.g. 'de' or 'en'
-U, --wordsStartWithUppercase
Set first character of each word to uppercase
-v, --verbose            be verbose.
-V, --version            Print version information and exit.
```

### Example Usages

```shell script
# Generate a password with 4 words, default number of digits, and delimiters in the default locale
./pwgen-cpp/pwgen-cpp 4

# Generate a password with 4 words, a number with 6 digits, and default delimiters in the default locale
./pwgen-rust/pwgen-rust 4 6

# Generate a password with 3 words, 5 digits, and custom delimiters
./pwgen-go/pwgen-go 3 5 "!@#"

# Generate a password with 4 words, with the first character of each word uppercased
./pwgen-java/pwgen-java -U 4

# Generate a password with 4 words, default number of digits, and delimiters 
# in the german locale
# using the uberjar
java -jar pwgen-java/target/pwgen-java-1-runner.jar -L de -U 4
```

# Source of wordlists

The german wordlist was collected manually.

https://github.com/bitcoin/bips/blob/master/bip-0039 contains french and english wordlists
which can be read via `src/resources/wordlists-load.sh`.
