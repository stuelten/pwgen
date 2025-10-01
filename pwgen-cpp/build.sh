#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact

# Setup for macOS
if [[ "Darwin" == "$(uname -s)" ]]; then
  brew install gcc make
elif [[ "Linux" == "$( uname -s )" ]]; then
  apt install gcc make
fi

make all
