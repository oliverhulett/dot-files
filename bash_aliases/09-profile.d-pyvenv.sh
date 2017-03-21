export PYVENV_HOME="${PYVENV_HOME:-${HOME}/opt/pyvenv}"

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

function venv_setup()
{
	source "${HOME}/dot-files/bash_common.sh" && eval "${capture_output}" || true
	PYVERSION=python2.7

	PYVENV_MARKER="${PYVENV_HOME}/.mark"
	if [ ! -e "${PYVENV_MARKER}" ] || [ "$(command cat "${PYVENV_MARKER}" 2>/dev/null)" != "$(pyvenv_version)" ]; then
		command ${VIRTUALENV} --no-site-packages -p /usr/bin/${PYVERSION} "$PYVENV_HOME" >&${log_fd} 2>&${log_fd}
		VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"

		pyvenv_version >"${PYVENV_MARKER}"

		## Need to export the path again, in-case activating the venv changed it.
		export PATH="$(prepend_path "${PYVENV_HOME}/bin")"
	fi
	( cd ${PYVENV_HOME}/bin && ln -vsf ${PYVERSION} python26 >&${log_fd} 2>&${log_fd} )
	( cd ${PYVENV_HOME}/bin && ln -vsf ${PYVERSION} python >&${log_fd} 2>&${log_fd} )
	eval "${uncapture_output}"
}

alias python='venv_setup; command python'
alias python26='venv_setup; command python26'
alias python2.7='venv_setup; command python2.7'
alias pip='venv_setup; command pip'
