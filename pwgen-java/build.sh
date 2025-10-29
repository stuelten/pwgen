#!/bin/bash
#
# Copyright 2025 Timo Stülten (pionira GmbH)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Use strict mode for Bash scripts:
# catch errors early and prevent silently ignoring failures.
set -eo pipefail

BASEDIR="$(dirname "$0")"

if [[ "$1" == "-q" || "$1" == "--quiet" ]]; then
  MVN_OPTIONS="--quiet $MVN_OPTIONS"
  shift
fi

if [[ "$1" == "--fast" ]]; then
  FAST=true
  shift
else
  # Install dependencies
  if [[ "Darwin" == "$(uname -s)" ]]; then
    # Setup for macOS
    brew install --quiet quarkusio/tap/quarkus
    # must be v21
    brew install --quiet --cask graalvm-jdk@21
    brew install --quiet maven
  elif [[ "Linux" == "$(uname -s)" ]]; then
    # Setup for Linux via SDKMan!
    curl -s "https://get.sdkman.io" | bash
    bash --login -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install quarkus'
    bash --login -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install java 25-graalce'
    bash --login -c 'source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install maven'
  fi
fi

if [[ -n "$FAST" ]]; then
  MVN_OPTIONS="-DskipTests $MVN_OPTIONS"
fi

# Setup for macOS
if [ "Darwin" == "$(uname -s)" ]; then
  GRAALVM_HOME="$(/usr/libexec/java_home -v 21 | grep graal)"
  export GRAALVM_HOME
  export JAVA_HOME="${GRAALVM_HOME}"
fi

if ("${JAVA_HOME}"/bin/javac -version >/dev/null); then
  echo "Use Java from ${JAVA_HOME}"
else
  echo "Error calling javac. Abort"
  exit 1
fi

# start from scratch
if [[ ! "$FAST" ]]; then
  mvn ${MVN_OPTIONS} clean
fi

echo
echo "Build Über-JAR"
# shellcheck disable=SC2086
mvn ${MVN_OPTIONS} package -Puberjar &&
  cp target/pwgen-*-runner.jar ./pwgen.jar

echo
echo "Build native binary"
if [ "Darwin" == "$(uname -s)" ]; then
  # shellcheck disable=SC2086
  mvn ${MVN_OPTIONS} package -Pnative &&
    cp target/pwgen-*-runner ./pwgen-java
  # all other programming langs create the binary with the lang name in the binary's name
  cp ./pwgen-java ./pwgen-macos

  if (docker ps >/dev/null 2>&1); then
    # build via docker image creates Linux binary
    echo
    echo "Build Linux Native Binary"
    # shellcheck disable=SC2086
    mvn ${MVN_OPTIONS} package -Pnative-linux &&
      cp target/pwgen-*-runner ./pwgen-linux
  fi
elif [ "Linux" == "$(uname -s)" ]; then
  # shellcheck disable=SC2086
  mvn ${MVN_OPTIONS} package -Pnative &&
    cp target/pwgen-*-runner ./pwgen-java
else
  echo ""
  echo "No macOS or Linux. Skip build."
fi

# Test freshly build native binary
"${BASEDIR}/native-test.sh"
