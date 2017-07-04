#!/bin/bash
## Steps to setup my VM...
## This script runs as the root user.

echo "Setting up user..."
USER="${1:-olihul}"
if [ -n "$2" ]; then
	HOME="$2"
else
	HOME="/home/${USER}"
fi
usermod -g users --append -G users,adm,wheel,vboxsf,root ${USER}

echo "Copying files provisioned into ${HOME} by base image..."
mkdir /tmp/home/
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
	chown ${USER} ${HOME}/etc/$f
	chgrp users ${HOME}/etc/$f
	chmod 0400 ${HOME}/etc/$f
done

if [ -e "${HOME}/etc/passwd" ]; then
	echo "Setting up samba..."
	( cat ${HOME}/etc/passwd; cat ${HOME}/etc/passwd; ) | smbpasswd -sa ${USER}

	echo "Bootstrapping GIT SSH keys..."
	curl -u "${USER}:$(cat ${HOME}/etc/passwd)" -X POST -H "Accept: application/json" -H "Content-Type: application/json" https://git/rest/ssh/1.0/keys -d '{"text": "'"$(cat ${HOME}/.ssh/id_rsa.pub)"'"}' 2>/dev/null
fi

echo "Cloning dot-files..."
su -c "cd ${HOME} && git config --global user.name 'Oliver Hulett' && git config --global user.email oliver.hulett@optiver.com.au" ${USER}
su -c "cd ${HOME} && git clone ssh://git@git.comp.optiver.com:7999/~${USER}/dot-files.git ${HOME}/dot-files" ${USER}
source "${HOME}/dot-files/bash_aliases/19-env-proxy.sh"
proxy_setup -q ${USER}
su -c "cd ${HOME}/dot-files && git submodule init && git submodule update" ${USER}
su -c "cd ${HOME}/dot-files && git commit --allow-empty -aqm "'"Vagrant setup autocommit: $(date -R)\n$(git status --short)"'" && git pull" ${USER}

mkdir ${HOME}/.dotlogs 2>/dev/null
chown ${USER} ${HOME}/.dotlogs
chgrp users ${HOME}/.dotlogs
source "${HOME}/dot-files/bash_common.sh" && eval "${capture_output}" || true
export PATH="$(prepend_path "${HOME}/dot-files/bin")"

su -c "${HOME}/dot-files/setup-home.sh" ${USER}

systemctl link "${HOME}/dot-files/autocommit.service"
systemctl start autocommit.service

echo "General clean-ups..."
rm -rf ${HOME}/Desktop 2>/dev/null
rmdir ${HOME}/{Documents,Downloads,Music,Pictures,Public,Templates,Videos} 2>/dev/null
systemctl stop collectd.service
systemctl disable collectd.service
systemctl stop timekeeper.service
systemctl disable timekeeper.service
sed --in-place -re 's/^CRONDARGS=(.*)-m ?off(.*)/CRONDARGS=\1\2/' /etc/sysconfig/crond
systemctl restart crond.service

echo "Restoring KDE and other personal configs..."
rsync -rAXog /H_DRIVE/etc ${HOME}/
find ${HOME}/etc -type f -print0 | xargs -0 chmod -x
chown -R ${USER} ${HOME}/etc
chgrp -R users ${HOME}/etc
rsync -rAXog --update ${HOME}/etc/backups/${HOME}/ ${HOME}/


# Some things are needed for the next set of background tasks.  Yakuake is needed for the GUI (autostart)
# Docker and jq are needed for docker-run.sh (see below)
yum install -y yakuake jq docker
sudo systemctl restart docker.service

NOHUP_FILE="${HOME}/.dotlogs/$(date '+%Y%m%d-%H%M%S')_vagrant-restart.log"
su -c "nohup ${HOME}/dot-files/Windoze/vagrant/install-things.sh >>${NOHUP_FILE} 2>>${NOHUP_FILE}" ${USER} &
disown -h
disown

echo "Restarting KDE to pick up restored backups..."
sudo systemctl restart gdm.service

true
