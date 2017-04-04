#!/bin/bash
## Steps to setup my VM...
## This script runs as the provisioning user.

echo "Setting up user..."
USER="$1"
HOME="/home/${USER}"
usermod -g users --append -G users,adm,wheel,vboxsf,root ${USER}

echo "Copying files provisioned into ${HOME} by base image..."
mkdir /tmp/home/ 2>/dev/null
mount /dev/mapper/vgdata-home.fs /tmp/home
rsync -rAXog /tmp/${HOME}/ ${HOME}/
umount /tmp/home/
rmdir /tmp/home/

echo "Setting up sudo..."
echo 'Defaults    secure_path = /home/olihul/dot-files/bin:/home/olihul/bin:/home/olihul/sbin:/optiver/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin' >/etc/sudoers.d/99_olihul

echo "Restoring backups..."
mkdir ${HOME}/etc 2>/dev/null
for f in passwd release.auth; do
	cp -v /H_DRIVE/etc/$f ${HOME}/etc/$f
	chown ${USER}:users ${HOME}/etc/$f
	chmod 0400 ${HOME}/etc/$f
done

if [ -e "${HOME}/etc/passwd" ]; then
	echo "Setting up samba..."
	( cat ${HOME}/etc/passwd; cat ${HOME}/etc/passwd; ) | smbpasswd -sa ${USER}

	echo "Bootstrapping GIT SSH keys..."
	curl -u "${USER}:$(cat ${HOME}/etc/passwd)" -X POST -H "Accept: application/json" -H "Content-Type: application/json" https://git/rest/ssh/1.0/keys -d '{"text": "'"$(cat ${HOME}/.ssh/id_rsa.pub)"'"}' 2>/dev/null
fi

echo "Cloning dot-files..."
su -c "git clone --recursive ssh://git@git.comp.optiver.com:7999/~${USER}/dot-files.git ${HOME}/dot-files" ${USER} 2>/dev/null
su -c "cd ${HOME}/dot-files && git commit --allow-empty -aqm "'"Vagrant setup autocommit: $(date -R)\n$(git status --short)"'" && git pull" ${USER}

source "${HOME}/dot-files/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

if ! echo "${HTTP_PROXY}" | grep -q "${USER}" 2>/dev/null; then
	source "${HOME}/dot-files/bash_aliases/19-env-proxy.sh" 2>/dev/null
	proxy_setup -q ${USER}
fi
su -c "${HOME}/dot-files/setup-home.sh" ${USER}

systemctl link "${HOME}/dot-files/backup.service"
systemctl start backup.service

echo "General clean-ups..."
rm -rf ${HOME}/Desktop 2>/dev/null
rmdir ${HOME}/{Documents,Downloads,Music,Pictures,Public,Templates,Videos} 2>/dev/null
systemctl stop collectd.service
systemctl disable collectd.service
systemctl stop timekeeper.service
systemctl disable timekeeper.service
sed --in-place -re 's/^CRONDARGS=(.*)-m ?off(.*)/CRONDARGS=\1\2/' /etc/sysconfig/crond
systemctl restart crond.service

echo "Installing some things I don't want to docker all the time..."
(
	# Install yakuake first, because I want it there when the provisioning finishes and GDM is restarted
	yum install -y yakuake
	yum groupinstall -y "development tools"
	yum install -y docker which wget curl telnet vagrant iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client protobuf-vim golang-vim jq \
		openssl-libs openssl-static java-1.8.0-openjdk-devel java-1.8.0-openjdk \
		python-devel python-pip libxml2-devel libxslt-devel \
		cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind clang-devel clang clang-analyzer \
		wireshark

	PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install -U pip
	PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install -U setuptools wheel
	PIP_CONFIG_FILE="${HOME}/dot-files/pip.conf" pip install pygments

	( cd /tmp && \
		curl http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx && \
		install -t /usr/local/bin drone && \
		rm drone
	)
) >&${log_fd} 2>&${log_fd} &
disown -h 2>/dev/null
disown 2>/dev/null

echo "Restoring local installs and other backups..."
(
	for d in /H_DRIVE/*; do
		d="$(basename -- $d)"
		rsync -rAXog /H_DRIVE/$d ${HOME}/
		find ${HOME}/$d -type f -print0 | xargs -0 chmod -x
		chown -R ${USER}:users ${HOME}/$d
	done
	chmod +x ${HOME}/opt/eclipse/eclipse ${HOME}/opt/sublime_text_3/sublime_text ${HOME}/opt/subl.sh ${HOME}/opt/clion-2016.3.2/bin/clion.sh
) >&${log_fd} 2>&${log_fd} &
disown -h 2>/dev/null
disown 2>/dev/null

echo "Copying cc-env custom files for eclipse indexer and friends..."
(
	CC_EXE="/usr/local/bin/cc-env"
	CC_IMAGE="$(sed -nre 's!.+(docker-registry\.aus\.optiver\.com/[^ ]+/[^ ]+).*!\1!p' "${CC_EXE}" 2>/dev/null | tail -n1)"
	mkdir --parents /media/cc-env/opt/ 2>/dev/null || true
	${HOME}/dot-files/bin/docker-run.sh -v /media/cc-env:/media/cc-env -u 0 ${CC_IMAGE} rsync -vpPAXrogthlm --delete /opt/optiver /media/cc-env/opt/optiver
) >&${log_fd} 2>&${log_fd} &
disown -h 2>/dev/null
disown 2>/dev/null

true
