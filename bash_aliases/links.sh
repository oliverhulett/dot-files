
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

