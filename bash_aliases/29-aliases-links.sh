
unalias brokenlinks 2>/dev/null
function brokenlinks
{
	find -L "$@" -not \( -name '.git' -prune -or -name '.svn' -prune \) -type l -exec ls -hdl --color=always "{}" \;
}

unalias rmbrokenlinks 2>/dev/null
function rmbrokenlinks
{
	find -L "$@" -not \( -name '.git' -prune -or -name '.svn' -prune \) -type l -exec ls -hdl --color=always "{}" \; -delete -print
}

unalias replacelink 2>/dev/null
function replacelink
{
	link="${2%%/}"
	if [ ! -h "$link" ]; then
		echo "$link is not a link"
		return 1
	fi
	orig="$(readlink -f "$link")"
	rm -v "$link" && ln -sv "$1" "$link" && return 0
	echo "Failed to replace link $link with '$1'"
	echo "Restoring original link to '$orig'"
	ln -sv "$orig" "$link"
}
