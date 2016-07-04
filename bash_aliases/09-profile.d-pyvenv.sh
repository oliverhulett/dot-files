export PYVENV_HOME="${PYVENV_HOME:-${HOME}/pyvenv}"

source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"
if ! reentered "${BASH_SOURCE}" <(echo ${PYVENV_HOME}) || [ ! -d "${PYVENV_HOME}" ]; then
	## Switch the ${HOME}/bin/virtualenv symlink to use a different version
	${HOME}/bin/virtualenv --no-site-packages "$PYVENV_HOME" >/dev/null 2>/dev/null
	VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"
fi

export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

