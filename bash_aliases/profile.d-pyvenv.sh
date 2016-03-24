export PYVENV_HOME="/home/olihul/pyvenv"

/home/olihul/bin/virtualenv --no-site-packages "$PYVENV_HOME" >/dev/null 2>/dev/null
VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"
