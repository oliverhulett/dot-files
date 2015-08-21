
unalias rmemptydir 2>/dev/null
function rmemptydir
{
	find "$@" -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read; do
		if [ -z "$(/bin/ls "$REPLY")" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

