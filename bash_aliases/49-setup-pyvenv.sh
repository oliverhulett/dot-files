# Set-up python virtual env
function python_setup()
{
	source "${HOME}/dot-files/bash_common.sh"
	eval $capture_output
	venv_setup

	## Install the things
	command pip install -U pip >&${log_fd}
	command pip install -U wheel setuptools >&${log_fd}
	command pip install -U -r "${HOME}/dot-files/python_setup.txt" >&${log_fd}
}
python_setup >/dev/null 2>/dev/null &
disown -h 2>/dev/null
disown 2>/dev/null
