# To pick up the latest recommended .bash_profile content,
# look in /etc/defaults/etc/skel/.bash_profile

# Modifying /etc/skel/.bash_profile directly will prevent
# setup from updating it.

export PATH="${PATH:-/bin:/usr/bin}"
source "${HOME}/dot-files/bash_common.sh"
if reentered "${HOME}/.bash_profile"; then
	return 0
fi

# ~/.bash_profile: executed by bash for login shells.

# source the system wide bashrc if it exists
if [ -e /etc/bash.bashrc ] ; then
	source /etc/bash.bashrc
fi

# source the users profile if it exists
if [ -e "${HOME}/.profile" ] ; then
	source "${HOME}/.profile"
fi

# source the users bashrc if it exists
if [ -e "${HOME}/.bashrc" ] ; then
	source "${HOME}/.bashrc"
fi

# Set MANPATH so it includes users' private man if it exists
if [ -d "${HOME}/man" ]; then
	MANPATH=${HOME}/man:${MANPATH}
fi

# Set INFOPATH so it includes users' private info if it exists
if [ -d "${HOME}/info" ]; then
	INFOPATH=${HOME}/info:${INFOPATH}
fi

export PATH
CLASSPATH="$PATH:."
export CLASSPATH

export LANGUAGE="en_AU:en"
export LC_MESSAGES="en_AU.UTF-8"
export LC_CTYPE="en_AU.UTF-8"
export LC_COLLATE="en_AU.UTF-8"
