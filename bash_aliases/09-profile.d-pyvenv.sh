# Guard against re-entrance!
if [ "${PYVENV_GUARD}" != "__ENTERED_PYVENV__$( ( echo ${PYVENV_HOME} && cat ${BASH_SOURCE} 2>/dev/null ) | md5sum)" ]; then
	PYVENV_GUARD="__ENTERED_PYVENV__$( ( echo ${PYVENV_HOME} && cat ${BASH_SOURCE} 2>/dev/null ) | md5sum)"
else
	return
fi

source "/home/olihul/etc/dot-files/bash_common.sh"

export PYVENV_HOME="/home/olihul/pyvenv"
if [ -f /.dockerenv ]; then
	export PYVENV_HOME="/home/olihul/py26venv"
fi

/home/olihul/bin/virtualenv --no-site-packages "$PYVENV_HOME" >/dev/null 2>/dev/null
VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"
export PATH="$(prepend_path "${PYVENV_HOME}/bin")"

