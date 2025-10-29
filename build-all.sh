#!/usr/bin/env bash
#
# Call build scripts for all languages

# base dir
BASE_DIR="$( pwd )"

# implementations to call
EXEC_LANGS="bash cpp go rust java python typescript"

for el in ${EXEC_LANGS}
do
  echo "" >&2
  echo "##########################################################################" >&2
  echo "# Build ${el}" >&2
  echo "#" >&2
  EXEC_DIR="${BASE_DIR}/pwgen-$el"
  cd "$EXEC_DIR" || exit

  time ./build.sh -q
  echo "" >&2

  cd "${BASE_DIR}" || exit
done

# echo results
echo
echo "##########################################################################" >&2
echo "# Results:"
ls -l pwgen-*/pwgen-*
