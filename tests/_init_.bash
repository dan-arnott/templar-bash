#!/usr/bin/env bash

##  Base Directory
declare DIR_BASE

##  Variables Directory
declare DIR_VARS

##  Test template file
declare DIR_TPLS

##  Temporary directory where tests are run
declare FIXTURE_ROOT

##  Template Script
declare TEMPLAR_SH

##  Test variables file
declare TEST_VARS

##  Test template file
declare TEST_TEMPLATE

##  Test output file
declare TEST_OUTPUT

##  Test sed commands file
declare TEST_SEDSCRIPT

##  Directory for bats tests and helpers
declare TESTS_ROOT


##  Configure fixtures based on type of testing
#
#   @param  $1  string  'integration, unit'
#
fixtures() {
  local \
    fixture_setup="${1}" \
    script='templar.bash' \
    dir_vars='vars' \
    dir_templates='tpls' \
    vars='test.bash' \
    template='test.tpl' \
    output='test.rst' \
    sedscript='query'

  if [[ 'unit' == ${fixture_setup} ]] ; then

    #****************************************************
    #   Fixture Setup configures testing directories
    #****************************************************
      ${fixture_setup} ${script} ${dir_vars} ${dir_templates} ${template}

    #****************************************************
    #   Define scripts in global variables
    #****************************************************
      TEMPLAR_SH="${DIR_BASE}/${script}"
      TEST_VARS="${DIR_VARS}/${vars}"
      TEST_TEMPLATE="${DIR_TPLS}/${template}"
      TEST_OUTPUT="${DIR_TPLS}/${output}"
      TEST_SEDSCRIPT="${DIR_TPLS}/${sedscript}"

  else
    return 1
  fi
}

##  Setup run prior to execution of each test
#
setup() {
  cd "${DIR_BASE}"
}

##  Configure Unit Test Environment
#
#   In unit tests, we recreate a new directory structure
#   and copy our scripts into that structure so that
#   tests can be run without interfering with production
#   environment.
#
#   @param  $1  string  name of template script
#   @param  $2  string  name of variables directory
#   @param  $3  string  name of templates directory
#
unit() {
  local \
    script="${1}" \
    dir_vars="${2}" \
    dir_templates="${3}" \
    template="${4}" \
    tmp_base="${BATS_TEST_DIRNAME}/.."
  local template="${tmp_base}/${dir_templates}/${template}"

  # where tests live
  TESTS_ROOT="${BATS_TEST_DIRNAME}"

  # where test fixtures live
  FIXTURE_ROOT="${TESTS_ROOT}/fixtures"

  # fixture root is different from DIR_BASE in unit tests but same in integration tests
  #change ${DIR_BASE} so vars file works
  DIR_BASE="${FIXTURE_ROOT}"

  DIR_VARS="${DIR_BASE}/${dir_vars}"

  DIR_TPLS="${DIR_BASE}/${dir_templates}"

  # Rebuild the fixtures directory structure
  rm -Rf "${DIR_BASE}"
  mkdir -p "${DIR_BASE}"
  mkdir -p "${DIR_TPLS}"

  # Repopulate the fixtures files
  cp "${tmp_base}/${script}"        "${DIR_BASE}/${script}"
  cp -R "${tmp_base}/${dir_vars}"   "${DIR_VARS}"
  cp "${template}"                  "${DIR_TPLS}"
}
