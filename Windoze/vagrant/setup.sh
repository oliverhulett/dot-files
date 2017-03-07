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
echo 'Defaults    secure_path = /home/olihul/bin:/home/olihul/sbin:/optiver/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin' >/etc/sudoers.d/99_olihul

echo "Restoring backups..."
rsync -rAXog /H_DRIVE/etc ${HOME}/
find ${HOME}/etc/ -type f -print0 | xargs -0 chmod -x
chmod 0400 ${HOME}/etc/passwd ${HOME}/etc/release.auth 2>/dev/null
chown -R ${USER}:users ${HOME}/etc
rsync -aAXog ${HOME}/etc/backups/${HOME}/ ${HOME}/

if [ -e "${HOME}/etc/passwd" ]; then
	echo "Setting up samba..."
	( cat ${HOME}/etc/passwd; cat ${HOME}/etc/passwd; ) | smbpasswd -sa ${USER}

	echo "Bootstrapping GIT SSH keys..."
	curl -u "${USER}:$(cat ${HOME}/etc/passwd)" -X POST -H "Accept: application/json" -H "Content-Type: application/json" https://git/rest/ssh/1.0/keys -d '{"text": "'"$(cat ${HOME}/.ssh/id_rsa.pub)"'"}' 2>/dev/null
fi

echo "Cloning dot-files..."
su -c "git clone --recursive ssh://git@git.comp.optiver.com:7999/~${USER}/dot-files.git ${HOME}/dot-files" ${USER} 2>/dev/null
su -c "cd ${HOME}/dot-files && git pull" ${USER}
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

	( cd /tmp && \
		curl http://downloads.drone.io/release/linux/amd64/drone.tar.gz | tar zx && \
		install -t /usr/local/bin drone && \
		rm drone
	)
) &
disown -r
disown

echo "Restoring local installs and other backups..."
(
	for d in /H_DRIVE/*; do
		d="$(basename $d)"
		rsync -rAXog /H_DRIVE/$d ${HOME}/
		find ${HOME}/$d -type f -print0 | xargs -0 chmod -x
		chown -R ${USER}:users ${HOME}/$d
	done
	chmod +x ${HOME}/opt/eclipse/eclipse
	chmod +x ${HOME}/opt/sublime_text_3/sublime_text
) &
disown -rh
disown -r

true
