## Pretty print JSON
function checkjson()
{
	for f in "$@"; do
		python -m json.tool "$f" >/dev/null && echo "$(python -m json.tool "$f")" >"$f"
	done
}

