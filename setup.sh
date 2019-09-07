#
# Commando setup action.
#

function __setup {
  local releasedir="$1"
  local projectdir="$2"

  local verbose_options=''
  if ${verbose}; then
    verbose_options='-v'
  fi

  # install bootstrap
  cp ${verbose_options} "$releasedir/commando.sh" "$projectdir"
  chmod ${verbose_options} +x "$projectdir/commando.sh"

  # prepare configuration
  if [ ! -d "$projectdir/.commando" ]; then
    mkdir "$projectdir/.commando"
  fi
  if [ ! -d "$projectdir/.commando/library" ]; then
    mkdir "$projectdir/.commando/library"
  fi

  # install default library modules
  cp ${verbose_options} -r "$releasedir/.commando/library" "$projectdir/.commando"

  # maybe install default config.sh module
  if [ ! -e "$projectdir/.commando/config.sh" ]; then
    cp ${verbose_options} -r "$releasedir/.commando/config.sh" "$projectdir/.commando/config.sh"
  fi
}
