#!/bin/bash
## Installs things into my VM...

USER="${1:-olihul}"
if [ -n "$2" ]; then
	HOME="$2"
else
	HOME="/home/${USER}"
fi

#source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
source "${HOME}/dot-files/bash_common.sh"
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

trap "" HUP

# Some things are needed for the next set of background tasks.  Yakuake is needed for the GUI (autostart)
# Docker and jq are needed for docker-run.sh (see below)
sudo yum install -y yakuake jq docker
sudo yum remove -y libgnome-keyring-devel python-keyring subversion-gnome pam-kwallet ksshaskpass kwallet subversion-kde
sudo systemctl restart docker.service
sleep 2

set +e

echo
echo "Restoring local installs and other backups..."

for d in /H_DRIVE/*; do
	d="$(basename -- $d)"
	rsync -vrl /H_DRIVE/$d ${HOME}/
	find ${HOME}/$d -type f -print0 | xargs -tr0 chmod -x
	chown -R ${USER} ${HOME}/$d
	chgrp -R users ${HOME}/$d
done
chmod -v +x ${HOME}/opt/pyvenv/bin/* ${HOME}/opt/eclipse/eclipse ${HOME}/opt/sublime_text_3/sublime_text ${HOME}/opt/subl.sh ${HOME}/opt/clion-2016.3.2/bin/clion.sh

echo
echo "Installing some things I don't want to docker all the time: yum..."

export PATH="$(prepend_path "${HOME}/dot-files/bin")"

sudo yum groupinstall -y "development tools"
sudo yum install -y which wget curl telnet vagrant iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client protobuf-vim golang-vim crudini \
		openssl-libs openssl-static java-1.8.0-openjdk-devel java-1.8.0-openjdk \
		python-devel python-pip libxml2-devel libxslt-devel gmp-devel \
		cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind clang-devel clang clang-analyzer \
		wireshark cabal-install pandoc

echo
echo "Installing some things I don't want to docker all the time: pip..."
# Install global things only; i.e. Things that other programs (e.g. vim) will use.
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" sudo pip install -U pip
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" sudo pip install -U setuptools wheel
PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" sudo pip install pygments flake8

echo
echo "Installing some more things I don't want to docker all the time..."

"$(dirname "$0")"/install-things-w-custom-proxy.sh "$@"

echo
echo "Copying cc-env custom files for eclipse indexer and friends..."

export PATH="$(prepend_path "${HOME}/dot-files/bin" "/optiver/bin")"

CC_EXE="/usr/local/bin/cc-env"
CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" | tail -n1)"
sudo mkdir --parents /media/cc-env/opt/ || true
${HOME}/dot-files/bin/docker-run.sh -v /media/cc-env:/media/cc-env -u 0 ${CC_IMAGE} rsync -vpPAXrogthlm --delete /opt/optiver /media/cc-env/opt/

echo
echo "Done"
