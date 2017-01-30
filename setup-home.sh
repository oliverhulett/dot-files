#!/bin/bash

echo "Creating bash aliases..."
mkdir --parents "${HOME}/.bash_aliases" 2>/dev/null
rm "${HOME}/.bash_aliases/"* 2>/dev/null
( cd "${HOME}/.bash_aliases" && ln -sf ../dot-files/bash_aliases/* ./ )
if [ -f "${HOME}/dot-files/bash_aliases.deny" ]; then
	echo "Removing denied bash aliases..."
	( cd "${HOME}/.bash_aliases" && rm $(command cat "${HOME}/dot-files/bash_aliases.deny") )
fi
echo "Linking dot files..."
for f in bash_logout bash_profile bashrc docker_favourites gitconfig gitignore git_wrappers interactive_commands invoke.py profile pydistutils.cfg pypirc vimrc vim; do
	rm "${HOME}/.$f" 2>/dev/null
	ln -sf dot-files/$f "${HOME}/.$f"
done
for f in bin; do
	rm "${HOME}/$f" 2>/dev/null
	ln -sf dot-files/$f "${HOME}/$f"
done
mkdir --parents "${HOME}/.pip" 2>/dev/null
for f in pip.conf; do
	rm "${HOME}/.pip/$f" 2>/dev/null
	( cd "${HOME}/.pip" && ln -sf ../dot-files/$f $f )
done
if [ -f "${HOME}/dot-files/crontab.$(hostname -s)" ]; then
	echo "Installing crontab from ~/dot-files/crontab.$(hostname)..."
	crontab <(head -n -2 "${HOME}/dot-files/crontab.$(hostname -s)")
elif [ -f "${HOME}/dot-files/crontab" ]; then
	echo "Installing crontab from ~/dot-files/crontab..."
	crontab "${HOME}/dot-files/crontab"
fi
