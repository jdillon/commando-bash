#
# Utility helpers
#

function __util_module {
  # puke if missing arguments
  function require_arguments {
    local count=${1}; shift
    if [ ${#@} == 0 ]; then
      die "Missing ${count} arguments"
    elif [ ${#@} != ${count} ]; then
      die "Unexpected arguments: $@"
    fi
  }

  # puke if any arguments are given
  function require_zero_arguments {
    if [ ${#@} != 0 ]; then
      die "Unexpected arguments: $@"
    fi
  }

  # puke if missing configuration variable
  function require_configuration {
    local name=${1}
    local value=${!name}
    if [ -z "$value" ]; then
      die "Missing configuration: $name"
    fi
  }

  declare -gA executables

  # resolve an executable
  function resolve_executable {
    local name="$1"
    local var="$2"

    log "Resolve executable: $name -> \$$var"

    # if already resolved, then skip
    set +o nounset
    local resolved="${executables[$name]}"
    set -o nounset
    if [ -n "$resolved" ]; then
      log "Already resolved: $name -> $resolved"
      return
    fi

    local executable
    eval executable="\$$var"

    if [ ! -x "$executable" ]; then
      set +o errexit
      executable=$(which ${name})
      set -o errexit

      if [ -x "$executable" ]; then
        log "Resolved executable: $name -> $executable"
        eval $var="$executable"
      else
        die "Unable to resolve executable: $name"
      fi
    fi

    executables[$name]="$executable"
  }

  # wrap output of command with snip markers
  function snip_output {
    log '----8<----'
    "${@}"
    log '---->8----'
  }

  #
  # Standard executables
  #

  # standard verbose options when verbose enabled
  function __verbose_options {
    if ${verbose}; then
      echo '-v'
    fi
  }

  # rm
  declare -g rm_executable='rm'
  function rm {
    resolve_executable 'rm' rm_executable
    "${rm_executable}" $(__verbose_options) "$@"
  }

  # delete directories
  function rmdirs {
    local path="$1"

    if [ -d "${path}" ]; then
      log "Deleting dir: ${path}"
      snip_output rm -rf "${path}"
    fi
  }

  # ln
  declare -g ln_executable='ln'
  function ln {
    resolve_executable 'ln' ln_executable
    "${ln_executable}" $(__verbose_options) "$@"
  }

  # mkdir
  declare -g mkdir_executable='mkdir'
  function mkdir {
    resolve_executable 'mkdir' mkdir_executable
    "${mkdir_executable}" $(__verbose_options) "$@"
  }

  # make directories
  function mkdirs {
    local path="$1"

    if [ ! -d "${path}" ]; then
      log "Creating dir: ${path}"
      snip_output mkdir -p "${path}"
    fi
  }

  # awk
  declare -g awk_executable='awk'
  function awk {
    resolve_executable 'awk' awk_executable
    "${awk_executable}" "$@"
  }
}

define_module __util_module "$@"
