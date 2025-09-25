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

# Sort wordlist
echo "Sort wordlist"
tempsort="$(basename "${0}")"
TMPFILE=$(mktemp -q /tmp/"${tempsort}".XXXXXX) || (
  echo "$0: Can't create temp file, exiting..."
  exit 1
)
WORDLIST=src/main/resources/wordlist_en.txt
cat $WORDLIST | sort --ignore-case | uniq \
  > "${TMPFILE}" && cat "${TMPFILE}" > $WORDLIST
rm "${TMPFILE}"

# Use wordlist file to create Java File containing all words
echo "Generate source file"
sed -e '/@@@WORDLIST@@@/ {' -e "r ${WORDLIST}" -e 'd' -e '}' \
    src/archive/resources/de/sty/Wordlist.java.template \
  > src/archive/resources/de/sty/Wordlist.java
