#!/usr/bin/env bash
#
# Commando setup.
#

set -o errexit
set -o nounset

#
# Output
#

function __output_helpers {
  font_bold=''
  font_normal=''
  font_underline=''
  font_standout=''
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

  # display verbose message if verbose enabled
  verbose="$COMMANDO_VERBOSE"
  function log {
    if [ ${verbose} = 'true' ]; then
      printf "$(BOLD VERBOSE): $*\n" >&2
    fi
  }
}

#
# Main
#

function __main {
  # resolve this script name
  basename=$(basename $0)

  # determine fully-qualified base directory
  basedir=$(dirname $0)
  basedir=$(cd "$basedir" && pwd)

  function self {
    log "Running: $0 $*"
    $0 "$@"
  }

  cd "$basedir"

  if ${verbose}; then
    log "Bash: $BASH $BASH_VERSINFO $BASH_VERSION"
    log "Base name: $basename"
    log "Base directory: $basedir"
    log "Project directory: $COMMANDO_PROJECT"
  fi

  # TODO

  echo "HERE"
}

#
# Bootstrap
#

__output_helpers

# compatibility check
if [ "$BASH_VERSINFO" != '4' ]; then
  die "Incompatible Bash detected: $BASH $BASH_VERSINFO $BASH_VERSION"
fi

__main "$@"