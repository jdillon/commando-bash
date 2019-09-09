#!/usr/bin/env bash
#
# Commando script.
#
# Reads configuration from a few locations:
#
# Commands - $basedir/.$progname/commands/*.sh
# Project  - $basedir/.$progname/config.sh
# User     - $basedir/$progname.rc
#
# NOTE: $progname resolves to whatever the name of the commando script is (sans .sh suffix)
#

set -o errexit
set -o nounset

# compatibility check
if [ "$BASH_VERSINFO" -lt '4' ]; then
  echo "ERROR: Incompatible Bash detected: $BASH $BASH_VERSINFO $BASH_VERSION"
  exit 2
fi

#
# Output
#

function __output_helpers {
  declare -g font_bold=''
  declare -g font_normal=''
  declare -g font_underline=''
  declare -g font_standout=''

  if [ -t 1 ]; then
    local ncolors=$(tput colors)
    if [ -n "$ncolors" -a "$ncolors" -ge 8 ]; then
      font_normal=$(tput sgr0)
      font_bold=$(tput bold)
      font_underline=$(tput smul)
      font_standout=$(tput smso)
    fi
  fi

  function BOLD {
    printf "${font_bold}$*${font_normal}"
  }

  function UL {
    printf "${font_underline}$*${font_normal}"
  }

  # display fatal message and exit
  function die {
    printf "$(BOLD FATAL): $*\n" >&2
    exit 1
  }

  # display error message
  function error {
    printf "$(BOLD ERROR): $*\n" >&2
  }

  # display warning message
  function warn {
    printf "$(BOLD WARN): $*\n" >&2
  }

  # display message
  function info {
    printf "$(BOLD INFO): $*\n" >&2
  }

  # display verbose message if verbose enabled
  declare -g verbose='false'
  function log {
    if [ ${verbose} = 'true' ]; then
      printf "$(BOLD VERBOSE): $*\n" >&2
    fi
  }
}

#
# Modules
#

function __module_system {
  declare -gA defined_modules
  declare -gA loaded_modules
  declare -gA prepared_modules

  function define_module {
    local fn="$1"
    local module_name="$2"
    log "Define module: $module_name -> $fn"
    defined_modules[$module_name]=${fn}
  }

  function load_modules {
    for source in "$@"; do
      if [ -d "$source" ]; then
        for script in ${source}/*.sh; do
          load_module "$script"
        done
      elif [ -f "$source" ]; then
        load_module "$source"
      fi
    done

    log "Loaded modules: ${!loaded_modules[@]}"
  }

  function load_module {
    local script="$1"
    if [ -f "$script" ]; then
      local module_name="$(basename $script)"
      log "Load module: $module_name -> $script"
      source "$script" "$module_name"
      loaded_modules[$module_name]="$script"
    else
      warn "Missing: $script"
    fi
  }

  function prepare_modules {
    for module_name in ${!loaded_modules[@]}; do
      prepare_module ${module_name}
    done
  }

  function prepare_module {
    local module_name=${1}
    log "Prepare module: $module_name"

    # resolve and invoke module initializer
    local fn=${defined_modules[$module_name]}
    ${fn}

    prepared_modules[${module_name}]=${fn}
  }

  function require_module {
    local module_name="$1"
    log "Require module: $module_name"

    # skip if module has already been prepared
    set +o nounset
    if [ -n "${prepared_modules[${module_name}]}" ]; then
      return
    fi
    set -o nounset

    prepare_module $module_name
  }
}

#
# Commands
#

function __command_system {
  declare -gA defined_commands

  function define_command {
    local name=$1
    local fn=$2
    log "Define command: $name -> $fn"

    # ensure given function is actually a function
    if [ "$(type -t $fn)" != 'function' ]; then
      die "Invalid command: $name -> $fn"
    fi

    defined_commands[$name]="$fn"
  }

  # run a named command with optional arguments
  function run_command {
    local command="$1"
    shift

    if ${verbose}; then
      log "Command: '$command'; ${#@} arguments"
      for arg in "${@}"; do
        log "  '$arg'"
      done
    fi

    # resolve command function
    set +o nounset
    local fn="${defined_commands[$command]}"
    set -o nounset

    if [ -z "$fn" ]; then
      die "Invalid command: $command"
    fi

    # handle default options
    local -a arguments
    for opt in "$@"; do
      case $opt in
        # give all commands help options
        -h|--help)
          run_command help "$command"
          return
          ;;
      esac
    done

    ${fn} "$@"
  }
}

#
# Main
#

function __main {
  # resolve this script name
  declare -g basename=$(basename $0)
  declare -g progname=$(basename -s .sh ${basename})

  # determine fully-qualified base directory
  declare -g basedir=$(dirname $0)
  basedir=$(cd "$basedir" && pwd)

  # re-run self with arguments
  function self {
    log "Running: $0 $*"
    "$0" "$@"
  }

  # display usage and exit
  function usage {
    printf "\nusage: $basename [options] <command> [command-options]

options:
  -h,--help       Show usage
  -v,--verbose    Verbose output
  --              Stop processing options

To see available commands:
  $(BOLD ${basename} help)\n\n"

    exit 2
  }

  cd "$basedir"
  __module_system
  __command_system

  # parse options and build command-line (command + command-options)
  local -a command_line
  for opt in "$@"; do
    local consume_remaining=false

    case $opt in
      -h|--help)
        usage
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -*)
        die "Unknown option: $opt"
        ;;
      --)
        shift
        consume_remaining=true
        ;;
      *)
        consume_remaining=true
        ;;
    esac

    if [ "$consume_remaining" = 'true' ]; then
      for extra in "$@"; do
        command_line+=("$1")
        shift
      done
      break
    fi
  done

  # check if we have a command-line or not
  set +o nounset
  local have_command=false
  if [ ${#command_line[@]} != 0 ]; then
    have_command=true
  fi
  set -o nounset

  if ${verbose}; then
    log "Bash: $BASH $BASH_VERSINFO $BASH_VERSION"
    log "Base name: $basename"
    log "Program name: $progname"
    log "Base directory: $basedir"

    # explain command-line
    if ${have_command}; then
      log "Command line; ${#command_line[@]} arguments"
      for arg in ${!command_line[@]}; do
        log "  '${command_line[$arg]}'"
      done
    fi
  fi

  load_modules ".$progname/library" ".$progname/config.sh"
  prepare_modules

  # load user customizations
  source "$progname.rc"

  # display usage if no arguments, else execute command
  if ${have_command}; then
    run_command "${command_line[@]}"
  else
    usage
  fi
}

#
# Bootstrap
#

__output_helpers

__main "$@"