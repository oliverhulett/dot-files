
unalias brokenlinks 2>/dev/null
function brokenlinks
{
	find -L "$@" -type l -exec ls -hdl --color=always "{}" \;
}

unalias rmbrokenlinks 2>/dev/null
function rmbrokenlinks
{
	find -L "$@" -type l -exec ls -hdl --color=always "{}" \; -delete
}

