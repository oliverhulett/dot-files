# shellcheck shell=bash
unalias rmemptyfiles 2>/dev/null
function rmemptyfiles()
{
	find "$@" -xdev -not \( -name '.Private' -prune -or -name '.git' -prune -or -name '.svn' -prune \) -type f -empty -delete -print
}

unalias findemptyfiles 2>/dev/null
function findemptyfiles()
{
	find "$@" -xdev -not \( -name '.Private' -prune -or -name '.git' -prune -or -name '.svn' -prune \) -type f -empty
}

unalias rmemptydir 2>/dev/null
function rmemptydir()
{
	find "$@" -xdev -not \( -name '.Private' -prune -or -name '.git' -prune -or -name '.svn' -prune \) -type d | while read -r; do
		if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
			rmdir -pv "$REPLY" 2>/dev/null
		fi
	done
}

unalias findemptydir 2>/dev/null
function findemptydir()
{
	find "$@" -xdev -not \( -name '.Private' -prune -or -name '.git' -prune -or -name '.svn' -prune \) -type d | while read -r; do
		if [ "$(command ls -BAUn "$REPLY")" == "total 0" ]; then
			ls -d "$REPLY" 2>/dev/null
		fi
	done
}
