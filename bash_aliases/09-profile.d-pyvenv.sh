export PYVENV_HOME="${PYVENV_HOME:-${HOME}/pyvenv}"

source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"

export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

function pyvenv_version()
{
	command python --version 2>&1
}

VIRTUALENV=virtualenv
for cmd in virtualenv virtualenv-2.7 virtualenv-27 virtualenv-2.6 virtualenv-26; do
	if command which $cmd 2>/dev/null >/dev/null; then
		VIRTUALENV="$cmd"
		if [ "$cmd" != "virtualenv" ]; then
			alias virtualenv="$cmd"
		fi
		break
	fi
done

function python_setup()
{
	PYVERSION=python2.7

	PYVENV_MARKER="${PYVENV_HOME}/.mark"
	if [ ! -e "${PYVENV_MARKER}" ] || [ "$(command cat "${PYVENV_MARKER}" 2>/dev/null)" != "$(pyvenv_version)" ]; then
		command ${VIRTUALENV} --no-site-packages -p /usr/bin/${PYVERSION} "$PYVENV_HOME" >/dev/null 2>/dev/null
		VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"

		pyvenv_version >"${PYVENV_MARKER}"

		## Need to export the path again, in-case activating the venv changed it.
		export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

		## Install the things
		(
			command pip install -U pip 2>/dev/null
			command pip install -U wheel setuptools 2>/dev/null
			command pip install -U protobuf==2.5.0 twisted argparse 'lxml<3.4' invoke docker-compose devpi pylint stashy >/dev/null 2>/dev/null
		) &
		disown -h
		disown -r
	fi
	( cd ${PYVENV_HOME}/bin && ln -sf ${PYVERSION} python26 2>/dev/null )
	( cd ${PYVENV_HOME}/bin && ln -sf ${PYVERSION} python 2>/dev/null )
}
python_setup
alias python='python_setup; command python'
alias python26='python_setup; command python26'
alias python2.7='python_setup; command python2.7'
alias pip='python_setup; proxy_setup; command pip'
