## Validate JSON
function jsoncheck()
{
	for f in "$@"; do
		echo -n "Validating '$f': "
		python -m json.tool "$f" >&${log_fd}
		if [ 0 -eq $? ]; then
			echo "Good"
		else
			echo "Failed"
		fi
	done
}

## Pretty print JSON
function jsonpretty()
{
	for f in "$@"; do
		python -m json.tool "$f" >&${log_fd} && echo "$(python -m json.tool "$f")" >"$f"
	done
}

