#!/usr/bin/env bash

##  this impacts the relative directory of helper scripts.
#
DIR_TESTS="$(pwd)/tests"

##  path to bats binary
#
#   if not installed by distribution package, we provide
#   the path relative to the test directory
#
BATS_BIN="${DIR_TESTS}/libs/bats/bin/bats"

runner() {
  local \
    test_file="${DIR_TESTS}/${1}.bats"

  if [[ -f "${test_file}" ]] ; then
    "${BATS_BIN}" "${test_file}"
  fi
}

runner 'unit'
runner 'assertions'

