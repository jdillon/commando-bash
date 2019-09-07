#
# Help system
#

function __help_module {
  #
  # help
  #

  __help_command_description='Display help for command or list commands'
  __help_command_syntax='[command]'

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
    eval description=\$${fn}_description
    eval syntax=\$${fn}_syntax
    eval help=\$${fn}_help
    set -o nounset

    if [ -n "$description" ]; then
      printf "\n$description\n"
    fi

    printf "\n$(BOLD USAGE)\n\n"
    printf "  $basename $command $syntax\n\n"

    # if no help is present use default
    if [ -z "$help" ]; then
      help='\
$(BOLD OPTIONS)

  -h,--help   Show usage
'
    fi

    # late render help text
    eval "printf \"$help\""
    printf '\n'
  }

  # FIXME: need better support for required tools
  wc_tool='gwc' # GNU wc
  tr_tool='tr'

  # display list of all commands
  function help_list_commands {
    # lookup all command names
    local commands=${!defined_commands[@]}

    # calculate max size of function, and adjust for display
    local sorted=$(echo ${commands} | ${tr_tool} ' ' '\n' | sort)
    local max_size=$(echo "$sorted" | ${wc_tool} --max-line-length)
    local col_size=$(expr ${max_size} + 4)

    printf '\nCommands:\n'
    for command in ${sorted}; do
      local fn="${defined_commands[$command]}"

      # lookup command description
      set +o nounset
      eval description=\$${fn}_description
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
