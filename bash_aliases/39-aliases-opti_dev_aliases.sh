
alias logarchive='ssh central-archive'
alias log-archive='ssh central-archive'
alias centralarchive='ssh central-archive'
alias central-archive='ssh central-archive'

alias sshrelay='ssh sshrelay'

unalias bt 2>/dev/null
function bt()
{
	for f in "$@"; do
		file "$f"
		exe="$(file "$f" | sed -nre "s/.+, from '([^ ]+).+")"
		echo bt | gdb -x - "$exe" "$f"
	done
}

alias operat='/usr/bin/sudo -iu operat'

## OMG, so dodgy...
alias taskset='/usr/bin/sudo -Eu operat /usr/bin/sudo taskset -c 1'
alias asroot='/usr/bin/sudo -Eu operat /usr/bin/sudo'
alias asoperat='/usr/bin/sudo -Eu operat'

