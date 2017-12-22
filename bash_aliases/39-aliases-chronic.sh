## If `chronic` doesn't exist, make a poor man's version.

function __chronic()
{
	local tmp="$(mktemp)" || return
	"$@"  >"$tmp" 2>&1
	local ret=$?
	[ "$ret" -eq 0 ] || cat "$tmp"
	rm -f "$tmp"
	return "$ret"
}

if ! command which chronic >/dev/null 2>/dev/null; then
	alias chronic=__chronic
fi
