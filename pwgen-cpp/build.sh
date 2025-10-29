#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact

# Setup for macOS or some debian-based linux
if [[ "Darwin" == "$(uname -s)" ]]; then
  brew install gcc make
elif [[ "Linux" == "$( uname -s )" ]]; then
  sudo apt install gcc make
fi

make all
