#!/usr/bin/env bash
#=============================================================
#
#   @description    development variables
#   @author         Dan Arnott <>
#
#   @note   | Values in the file are used for development
#           | and should be replaced in production.  The
#           | BUILD_MODE variable should be updated so these
#           | values don't get loaded accidentally.
#
#=============================================================

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Directories
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Determine absolute path of this script
declare SELF=`readlink -f "${BASH_SOURCE[0]}"`

if [[ -z ${DIR_VARS} ]] ; then
  declare DIR_VARS=$(cd ` dirname "${SELF}" ` && pwd)
fi

if [[ -z ${DIR_BASE} ]] ; then
  declare DIR_BASE=$(cd ` dirname "${DIR_VARS}/../" ` && pwd)
fi

DIR_TEMPLATES="${DIR_BASE}/tpls"

TEMPLATE="${DIR_TEMPLATES}/test.tpl"

SEDSCRIPT="${DIR_TEMPLATES}/query"

OUTPUT="${DIR_TEMPLATES}/test.rst"

TASK='parse'