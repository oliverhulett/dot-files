export PYVENV_HOME="${PYVENV_HOME:-${HOME}/pyvenv}"

source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"

export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

function pyvenv_version()
{
	get_real_exe python pip >/dev/null
	"$REAL_PYTHON" --version 2>&1
	#"$REAL_PIP" --version 2>&1
}
PYVENV_MARKER="${PYVENV_HOME}/.mark"
if [ ! -e "${PYVENV_MARKER}" -o "$("$REAL_CAT" "${PYVENV_MARKER}" 2>/dev/null)" != "$(pyvenv_version)" ]; then
	## Switch the ${HOME}/bin/virtualenv symlink to use a different version
	${HOME}/bin/virtualenv --no-site-packages "$PYVENV_HOME" >/dev/null 2>/dev/null
	VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"

	pyvenv_version >"${PYVENV_MARKER}"

	## Need to export the path again, in-case activating the venv changed it.
	export PATH="$(prepend_path "${PYVENV_HOME}/bin")"
fi

