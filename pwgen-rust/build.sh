#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact

# Install rust if not present
if [[ ! -r "$HOME/.rustup/settings.toml" ]]; then
  if [[ "Darwin" == "$(uname -s)" || "Linux" == "$(uname -s)" ]]; then
    curl https://sh.rustup.rs -sSf | sh
  fi
fi

# Build
cargo build --release
