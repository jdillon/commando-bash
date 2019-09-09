#
# Help system
#

function __help_module {
  require_module util.sh

  declare -gA help_descriptions
  declare -gA help_syntaxs
  declare -gA help_docs

  function help_define_description {
    local command=${1}; shift
    local description="$*"
    log "Define $command help description: $description"
    help_descriptions[$command]="$description"
  }

  function help_define_syntax {
    local command=${1}; shift
    local syntax="$*"
    log "Define $command help syntax: $syntax"
    help_syntaxs[$command]="$syntax"
  }

  function help_define_doc {
    local command=${1}; shift
    local usage="$*"
    log "Define $command help usage: $usage"
    help_docs[$command]="$usage"
  }

  #
  # help
  #

  help_define_description help 'Display help for command or list commands'
  help_define_syntax help '[command]'

  function __help_command {
    set +o nounset
    local command="$1"
    set -o nounset

    # if given a command attempt to display its help
    if [ -n "$command" ]; then
      help_display_command_help ${command}
    else
      # otherwise list all commands
      help_list_commands
    fi
  }

  define_command 'help' __help_command

  # display help for given command
  function help_display_command_help {
    local command="$1"

    # resolve command function
    set +o nounset
    local fn="${defined_commands[$command]}"
    set -o nounset
    if [ -z "$fn" ]; then
      die "Invalid command: $command"
    fi

    # lookup command attributes
    set +o nounset
    local description="${help_descriptions[$command]}"
    local syntax="${help_syntaxs[$command]}"
    local usage="${help_docs[$command]}"
    set -o nounset

    if [ -n "$description" ]; then
      printf "\n$description\n"
    fi

    printf "\n$(BOLD USAGE)\n\n"
    printf "  $basename $command $syntax\n\n"

    # if no usage is present use default
    if [ -z "$usage" ]; then
      usage='\
$(BOLD OPTIONS)

  -h,--help   Show usage
'
    fi

    # late render usagse text
    eval "printf \"$usage\""
    printf '\n'
  }

  # determine maximum line-length of input
  function max_line_length {
    awk 'length > max_length { max_length = length } END { print max_length }' -
  }

  # display list of all commands
  function help_list_commands {
    # lookup all command names
    local commands=${!defined_commands[@]}

    # calculate max length of command name, and adjust for display
    local sorted=$(echo ${commands} | tr ' ' '\n' | sort)
    local max_size=$(echo "$sorted" | max_line_length)
    local col_size=$(expr ${max_size} + 4)

    printf '\nCommands:\n'
    for command in ${sorted}; do
      # lookup command description
      set +o nounset
      local description="${help_descriptions[$command]}"
      set -o nounset

      # $(BOLD) helper messes up printf ability to format
      if [ -n "$description" ]; then
        printf "  ${font_bold}%-${col_size}s${font_normal} %s\n" "${command}" "$description"
      else
        printf "  ${font_bold}${command}${font_normal}\n"
      fi
    done
    printf '\n'
  }
}

define_module __help_module "$@"
