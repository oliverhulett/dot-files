
unalias rmemptydir 2>/dev/null
function rmemptydir
{
	find "$@" -xdev -type d -not -wholename '*/.svn/*' | while read; do
		if [ -z "$(/bin/ls "$REPLY")" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

