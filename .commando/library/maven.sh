#
# Maven support
#

function __maven_module {
  declare -g maven_executable=
  declare -g maven_options=

  function mvn {
    resolve_executable 'mvn' "$maven_executable" maven_executable
    log "Running: $maven_executable $maven_options $*"
    "$maven_executable" ${maven_options} "$@"
  }
}

require_module util.sh

define_module __maven_module "$@"
