#!/usr/bin/env bash
#
# 1. Install prerequisites
# 2. Build artifact
# 3. Move to root dir

# Setup for macOS or some debian-based linux
if [[ "Darwin" == "$(uname -s)" ]]; then
  brew install npm
elif [[ "Linux" == "$( uname -s )" ]]; then
  sudo apt install npm
fi

npm install
npm run build:bin

cp dist/bin/pwgen-typescript .
