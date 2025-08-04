# pwgen Project

Creates passwords
which are easy enough to be remembered
(or transferred via audio/telephone)
while being secure enough for usage.

The base idea is stolen from xkcd.com: https://preshing.com/20110811/xkcd-password-generator/.

## Command Line Options

The application supports the following command line options:

- `<number>`: Number of words to combine (required)
- `<numberOfDigits>`: Generate this number of digits (default: 3)
- `<delimiters>`: Delimiters to use between words (default: =/*-+)
- `-U, --wordsStartWithUppercase`: Set first character of each word to uppercase
- `-h, --help`: Show help message and exit
- `-V, --version`: Print version information and exit

### Example Usage

```shell script
# Generate a password with 4 words, default number of digits and delimiters
./target/pwgen-1-runner 4

# Generate a password with 3 words, 5 digits, and custom delimiters
./target/pwgen-1-runner 3 5 "!@#"

# Generate a password with 4 words, with first character of each word uppercase
./target/pwgen-1-runner -U 4
```

## Native Apps via Quarkus and GraalVM

This project uses Quarkus and Graal to create native apps for macOS and linux.

The `build.sh` script contains the necessary steps
for the installation of GraalVM and Quarkus dependencies on macOS.
For the linux app, docker needs to be installed.

Calling `build.sh` on macOS creates both native apps
and copies them into the project's root directory
with the names `pwgen-macos` and `pwgen-linux`.
