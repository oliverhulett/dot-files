export PYVENV_HOME="${PYVENV_HOME:-${HOME}/pyvenv}"

source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"

export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

function pyvenv_version()
{
	command python --version 2>&1
}

function python_setup()
{
	PYVERSION=python2.7
	
	PYVENV_MARKER="${PYVENV_HOME}/.mark"
	if [ ! -e "${PYVENV_MARKER}" ] || [ "$(command cat "${PYVENV_MARKER}" 2>/dev/null)" != "$(pyvenv_version)" ]; then
		#virtualenv --no-site-packages -p /usr/local/bin/python3.5 "$PYVENV_HOME" >/dev/null 2>/dev/null
		virtualenv --no-site-packages -p /usr/bin/${PYVERSION} "$PYVENV_HOME" >/dev/null 2>/dev/null
		VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"
	
		pyvenv_version >"${PYVENV_MARKER}"
	
		## Need to export the path again, in-case activating the venv changed it.
		export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

		## Install the things
		pip install -U protobuf==2.5.0 twisted argparse 'lxml<3.4' invoke docker-compose devpi pylint >/dev/null 2>/dev/null
	fi
	( cd ${PYVENV_HOME}/bin && ln -sf ${PYVERSION} python26 2>/dev/null )
	( cd ${PYVENV_HOME}/bin && ln -sf ${PYVERSION} python 2>/dev/null )
}
python_setup
alias python='python_setup; command python'
alias python26='python_setup; command python26'
alias python2.7='python_setup; command python2.7'
