source "${HOME}/etc/dot-files/bash_common.sh"
unalias ssh 2>/dev/null
alias ssh='ssh.sh'

unalias sshname 2>/dev/null
function sshname()
{
	get_real_exe ssh >/dev/null
	if [ -z "${REAL_SSH}" ]; then
		REAL_SSH="/usr/bin/ssh"
	fi
	if [[ "$1" =~ ^([0-9]{1,4})$ ]]; then
		svrnum="$(printf '%04d' ${BASH_REMATCH[1]})"
		svrloc="sy"
	elif [[ "$1" =~ ^([a-z]+)([0-9]{1,4})$ ]]; then
		svrnum="$(printf '%04d' ${BASH_REMATCH[2]})"
		svrloc="${BASH_REMATCH[1]}"
	else
		echo 2>&1 "Bad server name pattern.  Want [<location>]<number>"
		return
	fi
	if [ -z "$svrnum" ]; then
		echo 2>&1 "Could not determine which server number you wanted."
		return
	fi
	target="op${svrloc}nxsr${svrnum}"
	host="$($REAL_SSH -o ConnectTimeout=2 -o PasswordAuthentication=no ${target} hostname)"
	if [ -n "$host" ]; then
		echo $host
	else
		echo $target
	fi
}

