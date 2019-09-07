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

  cp ${verbose_options} "$releasedir/commando.sh" "$projectdir"
  chmod ${verbose_options} +x "$projectdir/commando.sh"

  cp ${verbose_options} -r "$releasedir/.commando" "$projectdir/"
}
