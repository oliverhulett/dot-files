## Set up python virtual env and supporting jazz
source "${HOME}/etc/dot-files/bash_common.sh"

PIP_TRUSTED_HOST=devpi.aus.optiver.com
PIP_INDEX_URL=http://devpi.aus.optiver.com/optiver/prod/+simple/

if [ ! -f "$HOME/.pip/pip.conf" ]; then
	mkdir "$HOME/.pip" 2>/dev/null >/dev/null
	echo "[global]" >>"$HOME/.pip/pip.conf"
	echo "index-url=${PIP_INDEX_URL}" >>"$HOME/.pip/pip.conf"
	echo "trusted-host=${PIP_TRUSTED_HOST}" >>"$HOME/.pip/pip.conf"
fi

if [ ! -f "$HOME/.pydistutils.cfg" ]; then
	echo "[upload]" >>"$HOME/.pydistutils.cfg"
	echo "repository=devpi" >>"$HOME/.pydistutils.cfg"
	echo "[register]" >>"$HOME/.pydistutils.cfg"
	echo "repository=devpi" >>"$HOME/.pydistutils.cfg"
	echo "[easy_install]" >>"$HOME/.pydistutils.cfg"
	echo "index-url=${PIP_INDEX_URL}" >>"$HOME/.pip/pip.conf"
fi

if [ ! -f "$HOME/.pypirc" ]; then
	echo "[distutils]" >>"$HOME/.pypirc"
	echo "index-servers=devpi" >>"$HOME/.pypirc"
	echo "[devpi]" >>"$HOME/.pypirc"
	echo "; This is the real username and password, it's not a placeholder" >>"$HOME/.pypirc"
	echo "username=optiver" >>"$HOME/.pypirc"
	echo "password=optiver" >>"$HOME/.pypirc"
	echo "repository=${PIP_INDEX_URL%/+simple/}" >>"$HOME/.pypirc"
fi

function do_pip()
{
	if [ -z "${PIP_AUTO_COMPLETE}" -o "${PIP_AUTO_COMPLETE}" != "1" ]; then
		if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
			source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
			proxy_setup
		fi
	fi
	REAL_PIP="$(get_real_exe $1)"
	shift
	## We need to use the same GCC version that was used by our system python.
	## `prepend_path` will prepend given paths in reverse order.
	(
		export PATH="$(prepend_path /usr/bin /usr/lib64/ccache)"
		"$REAL_PIP" "$@"
	)
}
alias pip3="do_pip pip3"
alias pip="do_pip pip"

function python_setup()
{
	if ! echo "${HTTP_PROXY}" | grep -q "`whoami`" 2>/dev/null; then
		source "${HOME}/.bash_aliases/19-env-proxy.sh" 2>/dev/null
		proxy_setup
	fi

	sudo -v

	pip install --upgrade pip wheel setuptools
	pip install --upgrade protobuf==2.5.0
	if grep -qE '2.6.*' <(python --version 2>&1) >/dev/null 2>/dev/null; then
		pip install --upgrade 'Twisted<15.4.0'
	else
		pip install --upgrade twisted
	fi
	pip install --upgrade sqlalchemy
	pip install --upgrade argparse
	sudo -n yum -y install unixODBC-devel
	pip install --upgrade pyodbc
	sudo -n yum -y install postgresql-devel
	pip install --upgrade psycopg2==2.5.4
	sudo -n yum -y install libxml2-devel libxslt-devel
	pip install --upgrade 'lxml<3.4'
}

