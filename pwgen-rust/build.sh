#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact

# Setup for macOS
if [[ "Darwin" == "$(uname -s)" ]]; then
  curl https://sh.rustup.rs -sSf | sh
elif [[ "Linux" == "$( uname -s )" ]]; then
  curl https://sh.rustup.rs -sSf | sh
fi

cargo build --release
