# pwgen-rust

This is the Rust implementation of the pwgen tool. It is a standard Cargo project, so you can build and run it with the Rust toolchain.

# HowTo build and run from the command line

## Prerequisites
- Install Rust (which includes cargo):
  - macOS/Linux:  
    `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
  - Windows:  
    Download and run the installer from https://rustup.rs/
- After installation, open a new shell and verify:
  - cargo --version
  - rustc --version

## Build
- From the repository root or from the pwgen-rust directory, run one of the following:
  - Using manifest path from repo root:  
    `cargo build --manifest-path pwgen-rust/Cargo.toml --release`
  - Or cd into the crate and build:  
    `cd pwgen-rust`  
    `cargo build --release`
- The optimized binary will be at:  
  `pwgen-rust/target/release/pwgen-rust`

## Run
- You can run directly with cargo:
  - From repo root:  
    `cargo run --manifest-path pwgen-rust/Cargo.toml -- 4 3 "=/*-+" -U -L de -v`
  - Or from pwgen-rust directory:  
    `cargo run -- 4 3 "=/*-+" -U -L de -v`
- Or run the built binary:
  `./pwgen-rust/target/release/pwgen-rust 4 3 "=/*-+" -U -L de -v`

## Command-line help
- The program accepts the same options as the Java version.
  See the Java version for details.
- Show usage and options:
  - `cargo run --manifest-path pwgen-rust/Cargo.toml -- --help`
  - or: `./pwgen-rust/target/release/pwgen-rust --help`

# Options

### Word lists (important)
- The program needs a word list for the chosen language.
  It looks in two locations (in this order):
  1) `pwgen-rust/wordlists/wordlist_<lang>.txt`
  2) `/etc/pwgen/wordlist_<lang>.txt` (fallback)
- Example languages: en, de. If no -L is provided, the program tries to use your system locale and falls back to en.

# Examples
- Default parameters in your system language (falls back to English):  
  `cargo run --manifest-path pwgen-rust/Cargo.toml --`
- 4 words, 5 digits inserted at a random position, custom delimiters, uppercase first letters:  
  `cargo run --manifest-path pwgen-rust/Cargo.toml -- 4 5 "!@#" -U`
- Force German word list, be verbose:  
  `cargo run --manifest-path pwgen-rust/Cargo.toml -- -L de -v 4`

# Notes
- The binary name is `pwgen-rust` (derived from the Cargo package name)
- the help text shows the command name as pwgen.
- Requires internet access on first build to fetch dependencies (clap, rand, locale_config).
