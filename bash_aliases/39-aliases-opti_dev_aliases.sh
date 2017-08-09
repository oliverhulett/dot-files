alias logarchive='ssh central-archive'
alias log-archive='ssh central-archive'
alias centralarchive='ssh central-archive'
alias central-archive='ssh central-archive'
alias centralstaging='ssh central-staging'
alias central-staging='ssh central-staging'

unalias bt 2>/dev/null
function bt()
{
	for f in "$@"; do
		file "$f"
		exe="$(file "$f" | sed -nre "s/.+, from '([^ ]+).+/\\1/p")"
		echo "bt $exe $f"
		echo
		( cd "$(dirname "$f")" && gdb -x <(echo bt) "$exe" "$(basename -- "$f")" )
	done
}

unalias stage 2>/dev/null
function stage()
{
	for f in "$@"; do
		b="$(basename -- "$f")"
		n="${b}.$(date '+%Y%m%d-%H%M%S')"
		d="/apps/bin/olihul"
		ssh central-staging "mkdir --parents $d"
		scp "$f" central-staging:"$d/$n"
		ssh central-staging "chmod 0775 '$d/$n'"
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
		log "[WARN] ${EXE} has changed, make sure you're still faking it right: LastHash=${OLD_MD5} NewHash=${NEW_MD5}"
		if [ ! -e "${HOME}/etc/backups/${EXE}" ] || [ "${NEW_MD5}" != "$(md5sum "${HOME}/etc/backups/${EXE}" | cut -d' ' -f1)" ]; then
			cp -v --parents --backup=numbered "${EXE}" "${HOME}/etc/backups/"
		fi
		log "Try: diff ${EXE} $(command ls -1 ${HOME}/etc/backups/${EXE}.* 2>/dev/null | sort --sort=version | tail -n1)"
		echo "Try: diff ${EXE} $(command ls -1 ${HOME}/etc/backups/${EXE}.* 2>/dev/null | sort --sort=version | tail -n1)"
		echo
	fi
}

unalias cc-env 2>/dev/null
function cc-env()
{
	CC_EXE="/usr/local/bin/cc-env"
	if [ ! -x "$CC_EXE" ]; then
		log "[FATAL] ${CC_EXE} does not exist"
		echo "[FATAL] ${CC_EXE} does not exist"
		return 1
	fi
	proxy_exe "${CC_EXE}" "e7f92198178a9c7bdb1b6c04ef679c08"
	CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" | tail -n1)"
	# does the app releases mount exists, then map it into the container
	[ -d /ApplicationReleases ] && MOUNT_APPRELEASES=( "-v" "/ApplicationReleases:/ApplicationReleases" ) || MOUNT_APPRELEASES=()
	[ -d /u01 ] && MOUNT_U01=( "-v" "/u01:/u01" ) || MOUNT_U01=()
	docker-run.sh "${MOUNT_U01[@]}" "${MOUNT_APPRELEASES[@]}" "${CC_IMAGE}" "$@"
	es=$?
	proxy_exe "${CC_EXE}" "e7f92198178a9c7bdb1b6c04ef679c08"
	return $es
}

alias operat='command sudo -iu operat'

## OMG, so dodgy...
alias taskset='command sudo -Eu operat sudo taskset -c 1'
alias asroot='command sudo -Eu operat sudo'
alias asoperat='command sudo -Eu operat'
