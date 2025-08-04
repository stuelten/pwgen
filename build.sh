#!/bin/bash
#
# Copyright 2024 Timo Stülten (pionira GmbH)
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

# Sort wordlist
echo "Sort wordlist"
tempsort="$(basename "${0}")"
TMPFILE=$(mktemp -q /tmp/"${tempsort}".XXXXXX) || (
  echo "$0: Can't create temp file, exiting..."
  exit 1
)

cat src/main/resources/wordlist_de.txt | sort --ignore-case | uniq \
  > "${TMPFILE}" && cat "${TMPFILE}" > src/main/resources/wordlist_de.txt
rm "${TMPFILE}"

# Use wordlist file to create Java File containing all words
echo "Generate source file"
sed -e '/@@@WORDLIST@@@/ {' -e 'r src/main/resources/wordlist_de.txt' -e 'd' -e '}' \
  src/main/resources/de/sty/Wordlist.java.template \
  > src/main/java/de/sty/Wordlist.java

if [ "$1" == "--pre-compile-only" ]
then
  echo "Only pre-compile steps executed. Exiting..."
  exit 0
fi

if [ "$1" == "-q" ] || [ "$1" == "--quiet" ]
then
  MVN_OPTIONS=--quiet
fi

# Setup for macOS
if [ "Darwin" == "$(uname -s)" ]; then
  # Install dependencies
  brew install quarkusio/tap/quarkus
  # must be v21
  brew install --cask graalvm-jdk@21

  brew install maven

  GRAALVM_HOME="$(/usr/libexec/java_home -v 21 | grep graal)"
  export GRAALVM_HOME
  export JAVA_HOME=${GRAALVM_HOME}
fi

if ( "${JAVA_HOME}"/bin/javac -version >/dev/null )
then
  echo "Use Java from ${JAVA_HOME}"
else
  echo "Error calling javac. Abort"
  exit 1
fi

echo "Build Uber-JAR"
# shellcheck disable=SC2086
mvn ${MVN_OPTIONS} clean package -Dquarkus.package.type=uber-jar

echo "Build native binary"
# shellcheck disable=SC2086
mvn ${MVN_OPTIONS} clean package -Pnative \
  && cp target/pwgen-*-runner ./pwgen-macos

if ( docker ps > /dev/null 2>&1 )
then
  # build via docker image creates Linux binary
  echo "Build Linux Native Binary"
  # shellcheck disable=SC2086
  mvn ${MVN_OPTIONS} clean package -Pnative -Dquarkus.native.container-build=true \
    && cp target/pwgen-*-runner ./pwgen-linux
else
  echo "Error calling docker. Skip build in docker container."
fi
