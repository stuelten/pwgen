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

BASEDIR="$(dirname "$0")"

if [[ "$1" == "--fast" ]]; then
  FAST=true
  shift
else
  # Sort wordlist
  "${BASEDIR}"/wordlist-generate.sh

  # Setup for macOS
  if [[ "Darwin" == "$(uname -s)" ]]; then
    # Install dependencies
    brew install quarkusio/tap/quarkus
    # must be v21
    brew install --cask graalvm-jdk@21

    brew install maven
  fi
fi

if [[ "$1" == "-q" || "$1" == "--quiet" ]]; then
  MVN_OPTIONS="--quiet $MVN_OPTIONS"
  shift
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
    cp target/pwgen-*-runner ./pwgen-macos
else
  if (docker ps >/dev/null 2>&1); then
    # build via docker image creates Linux binary
    echo
    echo "Build Linux Native Binary"
    # shellcheck disable=SC2086
    mvn ${MVN_OPTIONS} package -Pnative-linux &&
      cp target/pwgen-*-runner ./pwgen-linux
  else
    echo
    echo "Error calling docker. Skip build in docker container."
  fi
fi

# Test freshly build native binary
"${BASEDIR}/native-test.sh"
