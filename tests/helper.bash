#!/usr/bin/env bash

execute_templar_sh() {
  rm "${TEST_OUTPUT}"
  . "${TEMPLAR_SH}" -v "${TEST_VARS}" -i "${TEST_TEMPLATE}" -o "${TEST_OUTPUT}"
}

keep_sedscript() {
  rm "${TEST_SEDSCRIPT}"
  . "${TEMPLAR_SH}" -v "${TEST_VARS}" -i "${TEST_TEMPLATE}" -o "${TEST_OUTPUT}" -k
}