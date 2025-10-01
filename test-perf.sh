#!/usr/bin/env bash
#
# Execute pwgen-[*]/pwgen-[*] multiple times with the same options and measure the execution times

# Collects results
RES=""
# Options to call all executables with
OPTIONS="-L fr -U 8 6 ',-*/'"

# base dir
BASE_DIR="$( pwd )"

# implementations to call
EXEC_LANGS="cpp go rust java typescript"

for el in ${EXEC_LANGS}
do
  echo "# Try ${el}" >&2
  EXEC_DIR="${BASE_DIR}/pwgen-$el"
  cd "$EXEC_DIR" || exit
  EXEC=./pwgen-$el

  # execute 5 seconds and count how often the executable was executed
  count=0
  start=$(date +%s)
  while true; do
    $EXEC ${OPTIONS} 2>&1 || true
    count=$((count+1))
    now=$(date +%s)
    if [ $((now - start)) -ge 5 ]; then
      break
    fi
  done
  echo "# ${el}: executed ${count} times in 5s" >&2

  RES="$RES# ${el}: executed ${count} times in 5s\n"

  cd "${BASE_DIR}" || exit
done

# echo results
echo
echo "Results:"
echo -e "$RES" >&2

ls -l pwgen-*/pwgen-*
