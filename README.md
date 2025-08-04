# pwgen Project

Creates passwords
which are easy enough to be spoken
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

## Installation via Homebrew

On macOS, you can install pwgen using Homebrew:

### Option 1: Using a tap (recommended)

```shell
# Add the tap repository
brew tap timo-stuelten/pwgen https://github.com/timo-stuelten/homebrew-pwgen

# Install pwgen
brew install pwgen
```

### Option 2: Installing from a local formula

If you have the formula file locally, you can install it directly:

```shell
# Clone the repository
git clone https://github.com/timo-stuelten/pwgen.git
cd pwgen

# Install from the local formula
brew install --formula ./pwgen.rb
```

### Creating a Homebrew Tap Repository

To make your formula available via a tap, you need to:

1. Create a GitHub repository named `homebrew-pwgen`
2. Add the `pwgen.rb` formula file to this repository
3. Users can then tap your repository with `brew tap timo-stuelten/pwgen`

Before publishing:
- Update the URL in the formula to point to your actual release
- Calculate the SHA256 checksum with `shasum -a 256 pwgen-macos`
- Update the version to match your actual release version
