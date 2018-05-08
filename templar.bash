#!/usr/bin/env bash


# Determine absolute path of this script
declare SELF=`readlink -f "${BASH_SOURCE[0]}"`

# Set base directory based on this script
if [[ -z ${DIR_BASE} ]] ; then
  declare DIR_BASE=$(cd ` dirname "${SELF}" ` && pwd)
fi

# Set Variable Directory so value of -v switch can be set
if [[ -z ${DIR_VARS} ]] ; then
  declare DIR_VARS="${DIR_BASE}/vars"
fi

declare DEFAULT_VARS='default.bash'

declare GLOBAL_VARS

declare -l TASK='parse'

declare TEMPLATE

declare SEDSCRIPT

declare KEEP=1

declare OUTPUT

declare DELIMITER=':'

declare COMMANDS=()

declare -i QUIET=1

declare -i HELP=1


##  Provide help with syntax
#
function syntax_help {
  local \
    file="$( echo ${SELF} | rev | cut -d'/' -f1 | rev )"

  cat << SYNTAX

useage:  ${file} -v file -t task -i template [-e expressions -o output -d char -k -q]
         ${file} -h

OPTIONS:
   -v     Path to global variables
   -t     Task to perform
   -i     Template file
  [-h]    Help with syntax
  [-e]    Expressions file for SED
  [-o]    Output file
  [-d]    Delimiter character
  [-k]    Keep expressions file
  [-q]    Quiet messages and warnings

SYNTAX
}

##  Provide help with syntax and available targets
#
function task_help {
  syntax_help
  cat << HELP
==============================================================================
| TARGET            | DEFINITION                                             |
==============================================================================
  parse:              generate a file using a template and variables
  help:               print list of available targets
==============================================================================

HELP
}

##  Determine which tasks to run
#
#   @param $1 string  name of target task
#
function tasks {
  local                   \
    t="${1:-'help'}"      #  default task is "help".

  case "${t}" in
  #==============================================================================#
  #==============================================================================#
    "syntax"                ) syntax_help                                      ;;
    "parse"                 ) generate_output_file                             ;;
    "help"                  ) task_help                                        ;;
     *                      ) task_help                                        ;;
  #==============================================================================#
  esac
}

##  Initialize and test for required variables
#
function _init_ {
  local tmp

  # GLOBAL_VARS must be set
  if [[ -z "${GLOBAL_VARS}" ]] ; then
    prompt_for_vars_file
  fi

  load_vars_files "${GLOBAL_VARS}"

  # NOTE: this comes after loading globals because the
  #       template could be set there.
  if [[ ! -f "${TEMPLATE}" ]] ; then
    warning 'no template file supplied'
    warning 'NO NEED TO PROCEED!'
  else
    msg "using template file: `readlink -f "${TEMPLATE}"`"

    #
    if [[ -z ${SEDSCRIPT} ]] ; then
      tmp=`tempfile`
      warning 'no expressions file supplied'
      msg "creating expressions file: ${tmp}"
      SEDSCRIPT="${tmp}"
    fi

    # TASK must be set and load vars file successful
    if [[ -n "${TASK}" && $? -eq 0 ]] ; then
      tasks "${TASK}"
    else
      warning "a task was not specified"
    fi
  fi
}

##  Echo SELF filename without file extension
#
function get_filename {
  local             \
    file="$( echo ${SELF} | rev | cut -d'/' -f1 | rev )"
  echo ${file%%.*}
}

##  Prompt for GLOBAL_VARS if it hasn't been set
#
#   Attempts to suggest either the value of EXAMPLE_VARS
#   or the name of the SELF file (filename minus the extension).
#
function prompt_for_vars_file {
  local \
    filename='' \
    code=0

  printf '\n'
  warning 'missing global variables file'

  if [[ -z "${DEFAULT_VARS}" ]] ; then
    filename="${DIR_VARS}/$(get_filename)"
  else
    filename="${DIR_VARS}/${DEFAULT_VARS}"
  fi

  # Prompt for using temporary vars file
  if [[ -f "${filename}" ]] ; then
    while :; do
      read -p "Use the '${filename}' file: (y|n) " yn
      case $yn in
        [Yy]*) GLOBAL_VARS="${filename}"
               load_vars_files "${filename}"
               break ;;
        [Nn]*) syntax_help
               warning "A global variables file is required"
               unset TASK
               QUIET=0
               code=1
               break ;;
            *) echo "Please answer 'yes' or 'no': " ;;
      esac
    done

  # File must exist. There is no need to prompt
  # if it doesn't point to an actual file.
  else
    warning 'exiting. global vars file is required'
    syntax_help
    unset TASK
    QUIET=0
    code=1
  fi

  return ${code}
}

##  Parse a CSV string
#
#   @param  $1  csv string
#
function parse_csv {
  local csv="${1}"

  if [[ -n ${csv} ]] ; then
    echo "${csv//,/ }"
  fi
}

##  Checks the supplied global variable file before attempting to load it.
#
#   - Sends to prompt if a global variables file isn't set.
#   - Attempts to parse CSV if the global variable is not a file.
#
#   $1  string  file|path|string csv of filenames in the variables directory
#
function load_vars_files {
  local \
    globals=${1} \
    dir="${DIR_VARS}" \
    code=0

  # parse globals that are supplied as csv
  if [[ -n ${globals} && ! -f "${globals}" ]] ; then
    globals=$(parse_csv ${globals})
  fi

  for file in ${globals[@]} ; do

    path="${dir}/${file}"

    if [[ -f "${path}" ]] ; then
      source "${path}"
    elif [[ -f "${file}" ]] ; then
      source "${file}"
    else
      warning "missing variables file: '${file}'"
      TASK='syntax'
      code=1
    fi

  done

  return ${code}
}

##  Creates output file from a template using SED
#
generate_output_file() {
  local                       \
    template="${TEMPLATE}"    \
    output="${OUTPUT}"        \
    script="${SEDSCRIPT}"

  # Clean up after previous execution
  rm -f "${script}" "${output}"

  if [[ -f "${template}" ]] ; then
    create_expressions_script                           # sed expression list file
    msg 'creating output file'
    sed -f "${script}" <"${template}" > "${output}"     # create output file
  else
    warning 'template file is missing'
  fi
}

##  Create a file of expressions for use by SED
#
create_expressions_script() {
  local \
    template="${TEMPLATE}" \
    script=${SEDSCRIPT}

  update_expressions_list "${template}"

  if [[ ${#COMMANDS[@]} -eq 0 ]]; then
    warning 'No tokens found in template file.'
  else
    msg 'creating expression list'
    for expression in "${COMMANDS[@]}" ; do
      echo "${expression}" >> ${script}
    done
  fi
}

##  Update list of SED expressions to replace tokens identified in template file
#
#   @param  $1  string  path to template file
#
update_expressions_list() {
  local \
    template="${1}" \
    token \
    expression=''

  if [[ -f "${template}" ]] ; then

    msg 'building expressions list from template'
    for token in `find_tokens ${template}` ; do
      expression="$(generate_sed_expression ${token})"
      if [[ -n ${expression} ]] ; then
        COMMANDS+=("${expression}")  # skip any empty expressions
      fi
    done

  else
    warning "can't upate expressions list because template file is missing."
  fi
}

##  Returns string of tokens found in a file
#
#   $1 template
#
find_tokens() {
  local \
    template="${1}" \
    pattern patterns=('\{\{[A-Za-z0-9_]+=.+\}\}$' '\{\{\s*[0-9a-zA-Z_]+\s*\}\}') \
    tokens=''

  if [[ -f "${template}" ]] ; then
    for pattern in ${patterns[@]} ; do
      tokens+=("$(grep -oE ${pattern} "${template}" | uniq | sed -e 's/^{{//' -e 's/}}$//' )")
    done
  else
    warning 'missing template file.'
  fi

  echo ${tokens[@]}
}

##  Echo a SED expression to replace the supplied variable
#
#   Variables are supplied either with a default value (=) or not.  There are three cases:
#   1) No value exists and no default supplied => expression generation skipped
#   2) No value exists, but default supplied   => expression generation using default
#   3) Value exists (regardless of default)    => expression generation using value
#
#   $1   string   variables to build expression for
#  [$2]  string   delimiter character for SED
#   echo string   formatted SED expression
#
generate_sed_expression() {
  local \
    variable="${1}" \
    d="${2:-${DELIMITER}}" \
    substitution \
    expression

  echo ${variable} | grep -q =

  # no default value provided
  if [[ $? -gt 0 ]] ; then
    substitution="${!variable}"

  # default value present
  else
    # split using = as delimiter
    local tmp="${variable%=*}" substitution="${variable#*=}"

    # reassign substitution if a value for variable is defined elsewhere
    if [[ -n "${!tmp}" ]] ; then
      substitution="${!tmp}"
    fi
  fi

  # Only echo if both a variable and value have been assigned.
  if [[ -n "${variable}" && -n "${substitution}" ]] ; then
    expression="$(format_sed_expression "{{${variable}}}" "${substitution}" ${d})"
  fi

  echo "${expression}"
}

##  Add sed expressions to expression list
#
#   $1  pattern
#   $2  replacement
#   $3  delimiter
#
format_sed_expression() {
  local \
    pattern="${1}" \
    substitution="${2}" \
    d="${3:-${DELIMITER}}"

  echo "s${d}${pattern}${d}${substitution}${d} g"
}

##  Generate message for STOUT
#
#   @param $1  string  message to be formatted
#
msg() {
  local -l msgstring="${1}"
  local quiet=${QUIET}

  if [[ ${quiet} -ne 0 ]] ; then
    printf " \u2714 %s\n" "${msgstring}"
  fi
}

##  Generate message for STOUT
#
#   @param $1  string  warning message to be formatted
#
warning() {
  local -l msgstring="${1}"
  local quiet=${QUIET}

  if [[ ${quiet} -ne 0 ]] ; then
    printf " \u2718 %s\n" "${msgstring}"
  fi
}

##  Debug private functions
#
debug() {
  echo "w/o default:          '`generate_sed_expression 'BLUE'`'"
  echo "w default only:       '`generate_sed_expression 'BLUE=GREEN'`'"
  echo "w/o default w value:  '`generate_sed_expression 'KEEP'`'"
  echo "w default w value:    '`generate_sed_expression 'KEEP=FALSE'`'"

  echo "sed expression:       '`format_sed_expression 'blue' 'green' '/'`'"
  echo "tokens in template:   '`find_tokens "${TEMPLATE[@]}"`'"
  update_expressions_list "${TEMPLATE}"
  echo "commands generated:   '${#COMMANDS[@]}'"
}

##  Clean up GLOBAL VARS
#
#   It is suggested that this script is launched in a sub-shell when
#   launched by another script. (ie. `templat.bash -v ....` )
#
#   This ensures that global variables from one script don't overwrite
#   global vars by the same name created by another.
#
cleanup() {

  if [[ ${KEEP} -eq 0 ]] ; then
    : # skip
  else
    msg 'deleting expressions file'
    rm -f "${SEDSCRIPT}"
  fi

  msg "cleaning up global variables ${GLOBAL_VARS}"
  unset HELP
  unset QUIET
  unset GLOBAL_VARS
  unset DEFAULT_VARS
  unset TASK
  #-----------------
  unset COMMANDS
  unset SEDSCRIPT
  unset INPUT
  unset OUTPUT
  unset TEMPLATE
  unset DELIMITER
  unset KEEP
}

##  Process CLI options
#
#   @link  http://wiki.bash-hackers.org/howto/getopts_tutorial
#
OPTIND=1
while getopts "hkqv:t:e:o:i:d:" OPTION ; do
  case ${OPTION} in
    'h' ) HELP=0 ;;
    'k' ) KEEP=0 ;;
    'q' ) QUIET=0 ;;
    'v' ) GLOBAL_VARS=$OPTARG ;;
    't' ) TASK=$OPTARG ;;
    'e' ) SEDSCRIPT=$OPTARG ;;
    'o' ) OUTPUT=$OPTARG ;;
    'i' ) TEMPLATE=$OPTARG ;;
    'd' ) DELIMITER=$OPTARG ;;
  esac
done

if [[ 'help' == ${1} || ${HELP} -eq 0 ]] ; then
  QUIET=0 && syntax_help
elif [[ 'debug' == ${1} || 'debug' == ${TASK} ]] ; then
  QUIET=0 && debug
else
  _init_
fi

cleanup
