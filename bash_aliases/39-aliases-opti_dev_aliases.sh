alias logarchive='ssh central-archive'
alias log-archive='ssh central-archive'
alias centralarchive='ssh central-archive'
alias central-archive='ssh central-archive'
alias centralstaging='ssh central-staging'
alias central-staging='ssh central-staging'

alias sshrelay='ssh sshrelay'

unalias bt 2>/dev/null
function bt()
{
	for f in "$@"; do
		file "$f"
		exe="$(file "$f" | sed -nre "s/.+, from '([^ ]+).+/\\1/p")"
		echo "bt $exe $f"
		echo
		( cd "$(dirname "$f")" && gdb -x <(echo bt) "$exe" "$(basename "$f")" )
	done
}

function proxy_exe()
{
	EXE="$(readlink -f "$1")"
	OLD_MD5="$2"
	NEW_MD5="$(md5sum "${EXE}" | cut -d' ' -f1)"
	if [ "${OLD_MD5}" != "${NEW_MD5}" ]; then
		echo
		echo "[WARN] ${EXE} has changed, make sure you're still faking it right."
		echo "Last hash was: ${OLD_MD5}"
		md5sum "${EXE}"
		if [ ! -e "${HOME}/etc/backups/${EXE}" ] || [ "${NEW_MD5}" != "$(md5sum "${HOME}/etc/backups/${EXE}" | cut -d' ' -f1)" ]; then
			cp -v --parents --backup=numbered "${EXE}" "${HOME}/etc/backups/"
		fi
		echo "Try: diff ${EXE} $(command ls -1 ${HOME}/etc/backups/${EXE}.* 2>/dev/null | sort --sort=version | tail -n1)"
		echo
	fi
}

unalias cc-env 2>/dev/null
function cc-env()
{
	eval "${capture_output}"
	CC_EXE="/usr/local/bin/cc-env"
	if [ ! -x "$CC_EXE" ]; then
		echo "[FATAL] ${CC_EXE} does not exist"
		return -1
	fi
	proxy_exe "${CC_EXE}" "57c4472ab67a9cf67a8fbd81eeaa0e83"
	CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" 2>&${log_fd} | tail -n1)"
	docker-run.sh ${CC_IMAGE} "$@"
	es=$?
	proxy_exe "${CC_EXE}" "57c4472ab67a9cf67a8fbd81eeaa0e83"
	eval "${uncapture_output}"
	return $es
}

alias operat='command sudo -iu operat'

## OMG, so dodgy...
alias taskset='command sudo -Eu operat sudo taskset -c 1'
alias asroot='command sudo -Eu operat sudo'
alias asoperat='command sudo -Eu operat'
