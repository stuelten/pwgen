#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact

# Setup for macOS
if [[ "Darwin" == "$(uname -s)" ]]; then
  sudo brew install gcc make
elif [[ "Linux" == "$( uname -s )" ]]; then
  sudo apt install gcc make
fi

make all
