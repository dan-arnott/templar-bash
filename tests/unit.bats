#!/usr/bin/env bats
#=============================================================
#
#   @author         Dan Arnott <>
#
#   @param   -v   VARS       string   Path to the vars file
#   @param   -t   TASK       string   Task to bootstrap
#   @param   -i   TEMPLATE   string   Template file to parse
#   @param  [-h]  HELP       boolean  True for help
#   @param  [-e]  SEDSCRIPT  file     Expressions file for SED
#   @param  [-o]  OUTPUT     file     Output file
#   @param  [-d]  DELIMITER  string   Delimiter character
#   @param  [-k]  KEEP       boolean  Keep expressions file
#   @param  [-q]  QUIET      boolean  Messages and warnings are silent
#
#   @use    file -v file -t task -i template [-e expressions -o output -d char -k]
#           file -h
#
#=============================================================

load '_init_'
fixtures 'unit'
load_lib 'bats-support'
load_lib 'bats-assert'
load 'helper'


##  Make sure testing framework files exist
#
@test 'test bats files' {
  tests_dir="${TESTS_ROOT}"
  #-------------------------
  [[ -f "${tests_dir}/_init_.bash" ]]
  [[ -f "${tests_dir}/helper.bash" ]]
  [[ -f "${tests_dir}/unit.bats" ]]
}

##  Make sure project scripts exist
#
@test 'test project scripts' {
  #-------------------------
  [[ -d "${DIR_BASE}" ]]
  [[ -d "${DIR_VARS}" ]]
  [[ -d "${DIR_TPLS}" ]]

  [[ -f "${TEMPLAR_SH}" ]]
  [[ -f "${TEST_VARS}" ]]
  [[ -f "${TEST_TEMPLATE}" ]]

  [[ ${status} -eq 0 ]]
}

@test 'test output' {
  [[ -n "${TEST_OUTPUT}" ]]
  [[ ! -f "${TEST_OUTPUT}" ]]
  run execute_templar_sh
  #-------------------------
  [[ -f "${TEST_OUTPUT}" ]]
  [[ ${status} -eq 0 ]]
}

@test 'test sedscript' {
  [[ -n "${TEST_SEDSCRIPT}" ]]
  [[ ! -f "${TEST_SEDSCRIPT}" ]]
  run keep_sedscript
  #-------------------------
  [[ -f "${TEST_SEDSCRIPT}" ]]
  [[ ${status} -eq 0 ]]
}