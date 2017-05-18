## Validate JSON
function jsoncheck()
{
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
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
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	for f in "$@"; do
		python -m json.tool "$f" >&${log_fd} && echo "$(python -m json.tool "$f")" >"$f"
	done
}
