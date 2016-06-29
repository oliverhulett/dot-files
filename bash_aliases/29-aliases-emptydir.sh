
unalias rmemptydir 2>/dev/null
function rmemptydir()
{
	find "$@" -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read; do
		if [ "$(real_ls -BAUn "$REPLY")" == "total 0" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

unalias findemptydir 2>/dev/null
function findemptydir()
{
	find "$@" -xdev -not \( -name '.git' -prune -or -name '.svn' -prune \) -type d | while read; do
		if [ "$(real_ls -BAUn "$REPLY")" == "total 0" ]; then
			ls -d "$REPLY" 2>/dev/null
		fi
	done
}

