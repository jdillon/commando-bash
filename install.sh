#!/usr/bin/env bash
#
# Commando installer.
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

  if [ -t 1 ]; then
    local ncolors=$(tput colors)
    if [ -n "$ncolors" -a "$ncolors" -ge 8 ]; then
      font_normal=$(tput sgr0)
      font_bold=$(tput bold)
    fi
  fi

  function BOLD {
    printf "${font_bold}$*${font_normal}"
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

  function snip_output {
    log '----8<----'
    $@
    log '---->8----'
  }
}

#
# Main
#

function __main {
  # resolve this script name
  declare -g basename=$(basename $0)

  # when fetched remotely avoid confusion with detcted basename
  if [ "$basename" = 'bash' ]; then
    basename='install.sh'
  fi

  # determine fully-qualified base directory
  declare -g basedir=$(dirname $0)
  basedir=$(cd "$basedir" && pwd)

  # stable defaults for usage display
  local default_verbose=${verbose}
  local default_baseurl='https://github.com/jdillon/commando-bash'
  local default_version='master'

  # configurable options
  local baseurl=${default_baseurl}
  local version=${default_version}

  # display usage and exit
  function usage {
    printf "
Commando Installer

usage: $basename [options]

options:
  -h,--help             Show usage
  -v,--verbose          Verbose output; default: ${default_verbose}
  --version <version>   Select version; default: ${default_version}
  --baseurl <url>       Select base URL; default: ${default_baseurl}
  --                    Stop processing options
\n"

    exit 2
  }

  # parse options and collect arguments
  local -a arguments
  for opt in "$@"; do
    local consume_remaining=false

    case $opt in
      -h|--help)
        usage
        ;;
      -v|--verbose)
        shift
        verbose=true
        ;;
      --baseurl)
        baseurl="$2"
        shift 2
        ;;
      --version)
        version="$2"
        shift 2
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
        arguments+=("$1")
        shift
      done
      break
    fi
  done

  local disturl="$baseurl/archive/${version}.tar.gz"
  local tmpdir=`mktemp -d`
  local projectdir=$(pwd)

  if ${verbose}; then
    log "Bash: $BASH $BASH_VERSINFO $BASH_VERSION"
    log "Base name: $basename"
    log "Base directory: $basedir"
    log "Base URL: $baseurl"
    log "Version: $version"
    log "Distribution URL: $disturl"
    log "Temp directory: $tmpdir"
    log "Project directory: $projectdir"
    log "Arguments: ${arguments[@]}"
  fi

  info "Installing"

  if [[ ${baseurl} == file:* ]]; then
    # use local release distribution
    local releasedir=${baseurl:5}
    if [ ! -d ${releasedir} ]; then
      die "Invalid baseurl; not a directory: ${releasedir}"
    fi
  else
    # fetch release distribution
    local distfile="$tmpdir/dist.tgz"
    local distdir="$tmpdir/dist"
    local releasedir="$distdir/commando-bash-$version"

    info "Distribution archive: $distfile"
    curl --location --silent --output "$distfile" "$disturl"

    log "Distribution directory: $distdir"
    mkdir "$distdir"
    tar -xzf "$distfile" -C "$distdir"
  fi

  info "Release directory: $releasedir"

  local setup="$releasedir/setup.sh"
  if [ ! -f ${setup} ]; then
    die "Invalid release directory; missing: ${setup}"
  fi

  if ${verbose}; then
    snip_output find "$releasedir" -type f ! -path "*/.git*"
  fi

  info "Setup"
  source "$setup"
  __setup "$releasedir" "$projectdir"

  rm -rf "$tmpdir"

  info "Done"
}

#
# Bootstrap
#

__output_helpers

__main "$@"