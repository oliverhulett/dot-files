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
		t="$(cd "$(dirname -- "$f")" && git ticket)"
		if [ -n "$t" ]; then
			n="${b}.${t}.$(date '+%Y%m%d-%H%M%S')"
		else
			n="${b}.$(date '+%Y%m%d-%H%M%S')"
		fi
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

function cc-env-wrapper()
{
	CC_EXE="$1"
	shift
	CC_HASH="$1"
	shift

	if [ ! -x "$CC_EXE" ]; then
		log "[FATAL] ${CC_EXE} does not exist"
		echo "[FATAL] ${CC_EXE} does not exist"
		return 1
	fi
	proxy_exe "${CC_EXE}" "${CC_HASH}"
	CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" | tail -n1)"
	# does the app releases mount exists, then map it into the container
	[ -d /ApplicationReleases ] && MOUNT_APPRELEASES=( "-v" "/ApplicationReleases:/ApplicationReleases" ) || MOUNT_APPRELEASES=()
	[ -d /u01 ] && MOUNT_U01=( "-v" "/u01:/u01" ) || MOUNT_U01=()
	docker-run.sh "${MOUNT_U01[@]}" "${MOUNT_APPRELEASES[@]}" "${CC_IMAGE}" "$@"
	es=$?
	proxy_exe "${CC_EXE}" "${CC_HASH}"
	return $es
}
alias cc-env='cc-env-wrapper "/usr/local/bin/cc-env" "54ee89223c6d4b3117de03ab5847850f"'
alias cc-env-ng='cc-env-wrapper "/usr/local/bin/cc-env-ng" "746880a32bd493c8ca5bbb1993f0755c"'

alias operat='command sudo -iu operat'

## OMG, so dodgy...
alias taskset='command sudo -Eu operat sudo taskset -c 1'
alias asroot='command sudo -Eu operat sudo'
alias asoperat='command sudo -Eu operat'
