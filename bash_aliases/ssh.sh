## Wrap SSH to install ID keys.
unalias ssh 2>/dev/null
function ssh()
{
	get_real_exe ssh >/dev/null
	if [ -z "${REAL_SSH}" ]; then
		REAL_SSH="/usr/bin/ssh"
	fi
	if [ $# -eq 1 ]; then
		if ! echo $1 | grep -qw ${HOME}/.ssh/known_hosts; then
			if ! $REAL_SSH $1 -o PasswordAuthentication=no echo "Testing SSH connection to $1"; then
				ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub $1
			fi
		fi
	fi
	$REAL_SSH -Y "$@"
}

