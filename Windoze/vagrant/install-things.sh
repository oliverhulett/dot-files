#!/bin/bash
## Installs things into my VM...

USER="${1:-olihul}"
if [ -n "$2" ]; then
	HOME="$2"
else
	HOME="/home/${USER}"
fi

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

# Some things are needed for the next set of background tasks.  Yakuake is needed for the GUI (autostart)
# Docker and jq are needed for docker-run.sh (see below)
sudo yum install -y yakuake jq docker
sudo systemctl restart docker.service
sleep 2

set +e

echo
echo "Restoring local installs and other backups..."

source "${HOME}/dot-files/bash_common.sh" && eval "${capture_output}" || true
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

for d in /H_DRIVE/*; do
	d="$(basename -- $d)"
	rsync -vrl /H_DRIVE/$d ${HOME}/
	find ${HOME}/$d -type f -print0 | xargs -tr0 chmod -x
	chown -R ${USER} ${HOME}/$d
	chgrp -R users ${HOME}/$d
done
chmod -v +x ${HOME}/opt/pyvenv/bin/* ${HOME}/opt/eclipse/eclipse ${HOME}/opt/sublime_text_3/sublime_text ${HOME}/opt/subl.sh ${HOME}/opt/clion-2016.3.2/bin/clion.sh

echo
echo "Installing some things I don't want to docker all the time..."

source "${HOME}/dot-files/bash_common.sh" && eval "${capture_output}" || true
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

sudo yum groupinstall -y "development tools"
sudo yum install -y which wget curl telnet vagrant iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client protobuf-vim golang-vim crudini \
		openssl-libs openssl-static java-1.8.0-openjdk-devel java-1.8.0-openjdk \
		python-devel python-pip libxml2-devel libxslt-devel gmp-devel \
		cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind clang-devel clang clang-analyzer \
		wireshark cabal-install pandoc

# Install global things only; i.e. Things that other programs (e.g. vim) will use.
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install -U pip
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install -U setuptools wheel
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install pygments flake8


echo
echo "Installing some more things I don't want to docker all the time..."

if [ -e "${HOME}/.bash_aliases/19-env-proxy.sh" ]; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh"
	proxy_setup -qt ${USER}
fi

TMPDIR="$(mktemp -d)"
( cd "${TMPDIR}" && \
	curl -sS http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx && \
	sudo install -t /usr/local/bin drone; \
	rm drone 2>/dev/null || true
)
rm -rf "${TMPDIR}"

TMPDIR="$(mktemp -d)"
( cd "${TMPDIR}" && \
	HASKELL="https://haskell.org/platform/download/7.10.2/haskell-platform-7.10.2-a-unknown-linux-deb7.tar.gz" && \
	wget --no-verbose --limit-rate=5m "${HASKELL}" && tar -xzvf "$(basename "${HASKELL}")" && \
	sudo ./install-haskell-platform.sh && \
	cabal update && \
	sudo cabal --config-file="${HOME}/.cabal/config" install --global --prefix=/usr/local ShellCheck
)
rm -rf "${TMPDIR}"

if [ -e "${HOME}/.bash_aliases/19-env-proxy.sh" ]; then
	source "${HOME}/.bash_aliases/19-env-proxy.sh"
	proxy_setup -q ${USER}
fi


echo
echo "Copying cc-env custom files for eclipse indexer and friends..."

source "${HOME}/dot-files/bash_common.sh" && eval "${capture_output}" || true
export PATH="$(prepend_path "${HOME}/dot-files/bin" "/optiver/bin")"

CC_EXE="/usr/local/bin/cc-env"
CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" | tail -n1)"
sudo mkdir --parents /media/cc-env/opt/ || true
${HOME}/dot-files/bin/docker-run.sh -v /media/cc-env:/media/cc-env -u 0 ${CC_IMAGE} rsync -vpPAXrogthlm --delete /opt/optiver /media/cc-env/opt/


echo
echo "Done"

true
