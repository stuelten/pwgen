#!/usr/bin/env bash
#
# Call build scripts for all languages

# base dir
BASE_DIR="$( pwd )"

# implementations to call
EXEC_LANGS="cpp go rust java python typescript"

for el in ${EXEC_LANGS}
do
  echo "# Build ${el}" >&2
  EXEC_DIR="${BASE_DIR}/pwgen-$el"
  cd "$EXEC_DIR" || exit

  time ./build.sh -q

  cd "${BASE_DIR}" || exit
done

# echo results
echo
echo "Results:"
ls -l pwgen-*/pwgen-*
