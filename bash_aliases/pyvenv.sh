## Set up python virtual env and supporting jazz

export PYVENV_HOME="$HOME/pyvenv"

${HOME}/bin/virtualenv --no-site-packages "$PYVENV_HOME" >/dev/null 2>/dev/null
VIRTUAL_ENV_DISABLE_PROMPT=1 source "$PYVENV_HOME/bin/activate"

if [ ! -f "$HOME/.pip/pip.conf" ]; then
	mkdir "$HOME/.pip" 2>/dev/null >/dev/null
	echo "[global]" >>"$HOME/.pip/pip.conf"
	echo "index-url=http://devpi.aus.optiver.com/optiver/prod/+simple/" >>"$HOME/.pip/pip.conf"
	echo "trusted-host=devpi.aus.optiver.com" >>"$HOME/.pip/pip.conf"
fi

if [ ! -f "$HOME/.pydistutils.cfg" ]; then
	echo "[upload]" >>"$HOME/.pydistutils.cfg"
	echo "repository=devpi" >>"$HOME/.pydistutils.cfg"
	echo "[register]" >>"$HOME/.pydistutils.cfg"
	echo "repository=devpi" >>"$HOME/.pydistutils.cfg"
	echo "[easy_install]" >>"$HOME/.pydistutils.cfg"
	echo "index-url=http://devpi.aus.optiver.com/optiver/prod/+simple/" >>"$HOME/.pip/pip.conf"
fi

if [ ! -f "$HOME/.pypirc" ]; then
	echo "[distutils]" >>"$HOME/.pypirc"
	echo "index-servers=devpi" >>"$HOME/.pypirc"
	echo "[devpi]" >>"$HOME/.pypirc"
	echo "; This is the real username and password, it's not a placeholder" >>"$HOME/.pypirc"
	echo "username=optiver" >>"$HOME/.pypirc"
	echo "password=optiver" >>"$HOME/.pypirc"
	echo "repository=http://devpi.aus.optiver.com/optiver/prod/" >>"$HOME/.pypirc"
fi

function pip()
{
	if ! echo "${HTTP_PROXY}" | grep -q 'olihul' 2>/dev/null; then
		source "${HOME}/.bash_aliases/http_proxy.sh" 2>/dev/null
		proxy_setup
	fi
	if [ -z "$REAL_PIP" ]; then
		REAL_PIP="$(get_real_exe pip)"
	fi
	"$REAL_PIP" "$@"
}

function python_setup()
{
	if ! echo "${HTTP_PROXY}" | grep -q 'olihul' 2>/dev/null; then
		source "${HOME}/.bash_aliases/http_proxy.sh" 2>/dev/null
		proxy_setup
	fi

	sudo -v

	pip install --upgrade pip setuptools
	pip install protobuf==2.5.0
	pip install twisted
	pip install sqlalchemy
	pip install argparse
	sudo -n yum install unixODBC-devel
	pip install pyodbc
	sudo -n yum install postgresql-devel
	pip install psycopg2==2.5.4
	sudo -n yum install libxml2-devel libxslt-devel
	pip install lxml
}

