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

unalias cc-env 2>/dev/null
function cc-env()
{
	CC_EXE="/usr/local/bin/cc-env"
	if [ ! -x "$CC_EXE" ]; then
		echo "[FATAL] ${CC_EXE} does not exist"
		return -1
	fi
	if [ "$(md5sum "${CC_EXE}" | cut -d' ' -f1)" != "c78d61908e14ea86987db72adf7873e4" ]; then
		echo "[WARN] ${CC_EXE} has changed, make sure you're still faking it right.  Last hash was: c78d61908e14ea86987db72adf7873e4"
		md5sum "${CC_EXE}"
	fi
	CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" 2>/dev/null | tail -n1)"
	docker-run.sh ${CC_IMAGE} "$@"
	es=$?
	if [ "$(md5sum "${CC_EXE}" | cut -d' ' -f1)" != "c78d61908e14ea86987db72adf7873e4" ]; then
		echo "[WARN] ${CC_EXE} has changed, make sure you're still faking it right.  Last hash was: c78d61908e14ea86987db72adf7873e4"
		md5sum "${CC_EXE}"
	fi
	return $es
}

alias operat='command sudo -iu operat'

## OMG, so dodgy...
alias taskset='command sudo -Eu operat sudo taskset -c 1'
alias asroot='command sudo -Eu operat sudo'
alias asoperat='command sudo -Eu operat'
