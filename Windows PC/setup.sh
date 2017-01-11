#!/bin/bash
## Steps to setup my VM...

echo "Installing some things I don't want to docker all the time..."
yum install -y yakuake docker which wget curl telnet vagrant iotop nethogs sysstat aspell aspell-en cifs-utils samba samba-client wireshark protobuf-vim golang-vim jq

echo "Setting up user..."
USER="$1"
HOME="/home/${USER}"
usermod -g users --append -G users,adm,wheel,vboxsf,root ${USER}

echo "Setting up SSH from host machine's SSH files..."
cp -r /H_DRIVE/.ssh ${HOME}/
chmod -f 700 ${HOME}/.ssh
chmod -f 600 ${HOME}/.ssh/*
chmod -f 644 ${HOME}/.ssh/*.pub
sudo chown -R ${USER}:users ${HOME}/.ssh

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
su -c "cd ${HOME} && yes | git clone --recursive ssh://git@git.comp.optiver.com:7999/~${USER}/dot-files.git" ${USER}
su -c "cd ${HOME}/dot-files && git pull && git submodule init && git submodule sync && git submodule update" ${USER}
su -c "mkdir --parents ${HOME}/.bash_aliases" ${USER}
( cd ${HOME}/.bash_aliases/ && rm * 2>/dev/null )
( cd ${HOME}/.bash_aliases/ && su -c "ln -svf ../dot-files/bash_aliases/* ./" ${USER} )
for f in bash_profile profile bash_logout bashrc vim vimrc gitconfig git_wrappers gitignore pydistutils.cfg pypirc invoke.py; do
	su -c "rm ${HOME}/.$f 2>/dev/null; ln -sfv dot-files/$f ${HOME}/.$f" ${USER}
done
for f in bin; do
	su -c "rm ${HOME}/$f 2>/dev/null; ln -sfv dot-files/$f ${HOME}/$f" ${USER}
done
crontab -u ${USER} <(head -n -1 ${HOME}/dot-files/crontab)

echo "General clean-ups..."
rm -rf ${HOME}/Desktop 2>/dev/null
rmdir ${HOME}/{Documents,Downloads,Music,Pictures,Public,Templates,Videos} 2>/dev/null
sudo systemctl stop collectd.service

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