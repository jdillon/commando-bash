#
# Utility helpers
#

function __util_module {
  # complain if any arguments are given
  function zero_arguments {
    if [ ${#@} != 0 ]; then
      die "Unexpected arguments: $@"
    fi
  }

  # resolve an executable
  function resolve_executable {
    local name="$1"
    local executable="$2"
    local rvar="$3"

    if [ ! -x "$executable" ]; then
      set +o errexit
      executable=$(which ${name})
      set -o errexit

      if [ -x "$executable" ]; then
        log "Resolved executable: $name -> $executable"
        eval $rvar="$executable"
      else
        die "Unable to resolve executable: $name"
      fi
    fi
  }

  # wrap output of command with snip markers
  function snip_output {
    log '----8<----'
    $@
    log '---->8----'
  }

  function verbose_options {
    if ${verbose}; then
      echo '-v'
    fi
  }

  resolve_executable 'rm' '' rm_executable

  function rm {
    ${rm_executable} $(verbose_options) "$@"
  }

  resolve_executable 'ln' '' ln_executable

  function ln {
    ${ln_executable} $(verbose_options) "$@"
  }

  resolve_executable 'mkdir' '' mkdir_executable

  function mkdir {
    ${mkdir_executable} $(verbose_options) "$@"
  }

  # make directories
  function mkdirs {
    local path="$1"

    if [ ! -d "${path}" ]; then
      log "Creating dir: ${path}"
      snip_output mkdir -p "${path}"
    fi
  }

  # delete directories
  function rmdirs {
    local path="$1"

    if [ -d "${path}" ]; then
      log "Deleting dir: ${path}"
      snip_output rm -rf "${path}"
    fi
  }
}

define_module __util_module "$@"
