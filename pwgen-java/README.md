# pwgen-java

## Command Line Options

The application supports the following command line options:

```
target/pwgen-java-1-runner --help
Usage: pwgen [-hUvV] [-L=<lang>] [<number>] [<numberOfDigits>] [<delimiters>]
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

### Example Usage

```shell script
# Generate a password with 4 words, default number of digits and delimiters in the default locale
./target/pwgen-java-1-runner 4

# Generate a password with 3 words, 5 digits, and custom delimiters
./target/pwgen-java-1-runner 3 5 "!@#"

# Generate a password with 4 words, with first character of each word uppercase
./target/pwgen-java-1-runner -U 4

# Generate a password with 4 words, default number of digits and delimiters 
# in the german locale
# using the uberjar
java -jar target/pwgen-java-1-runner.jar -L de -U 4
```

## Native Apps via Quarkus and GraalVM

This project uses Quarkus and Graal to create native apps for macOS and linux.

The `build.sh` script contains the necessary steps
for the installation of GraalVM and Quarkus dependencies on macOS.
For the linux app, docker needs to be installed.

Calling `build.sh` on macOS creates both native apps
and copies them into the project's root directory
with the names `pwgen-macos` and `pwgen-linux`.
