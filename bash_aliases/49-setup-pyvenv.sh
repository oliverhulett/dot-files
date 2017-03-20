# Set-up python virtual env
function python_setup()
{
	source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
	venv_setup

	## Install the things
	command pip -q install -U pip >&${log_fd}
	command pip -q install -U wheel setuptools >&${log_fd}
	command pip -q install -U -r "${HOME}/dot-files/python_setup.txt" >&${log_fd}
	eval "${uncapture_output}"
}
python_setup >/dev/null 2>/dev/null &
disown -h 2>/dev/null
disown 2>/dev/null
