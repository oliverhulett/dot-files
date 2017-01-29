#!/bin/bash
## Steps to setup my VM...

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
sudo chown -R ${USER}:users ${HOME}/etc
rsync -aAXog ${HOME}/etc/backups/${HOME}/ ${HOME}/

if [ -e "${HOME}/etc/passwd" ]; then
	echo "Setting up samba..."
	( cat ${HOME}/etc/passwd; cat ${HOME}/etc/passwd; ) | sudo smbpasswd -sa ${USER}
	
	echo "Bootstrapping GIT SSH keys..."
	curl -u "${USER}:$(cat ${HOME}/etc/passwd)" -X POST -H "Accept: application/json" -H "Content-Type: application/json" https://git/rest/ssh/1.0/keys -d '{"text": "'"$(cat ${HOME}/.ssh/id_rsa.pub)"'"}' 2>/dev/null
fi

echo "Cloning dot-files..."
su -c "cd ${HOME} && git clone --recursive ssh://git@git.comp.optiver.com:7999/~${USER}/dot-files.git" ${USER} 2>/dev/null
su -c "cd ${HOME}/dot-files && git pull && git submodule init && git submodule sync && git submodule update" ${USER}
su -c "${HOME}/dot-files/setup-home.sh" ${USER}

echo "General clean-ups..."
rm -rf ${HOME}/Desktop 2>/dev/null
rmdir ${HOME}/{Documents,Downloads,Music,Pictures,Public,Templates,Videos} 2>/dev/null
sudo systemctl stop collectd.service

echo "Installing some things I don't want to docker all the time..."
(
	yum groupinstall -y "development tools"
	yum install -y docker which wget curl telnet vagrant iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client protobuf-vim golang-vim jq \
		openssl-libs openssl-static java-1.8.0-openjdk-devel java-1.8.0-openjdk \
		python-devel python-pip libxml2-devel libxslt-devel \
		cmake ccache distcc protobuf protobuf-c protobuf-python protobuf-compiler valgrind clang-devel clang clang-analyzer \
		yakuake wireshark
) &

echo "Restoring Eclpise install and other backups..."
(
	for d in /H_DRIVE/*; do
		d="$(basename $d)"
		rsync -rAXog /H_DRIVE/$d ${HOME}/
		find ${HOME}/$d -type f -print0 | xargs -0 chmod -x
		sudo chown -R ${USER}:users ${HOME}/$d
	done
	sudo chmod +x ${HOME}/opt/eclipse/eclipse
) &

true
