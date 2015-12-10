# To pick up the latest recommended .bash_profile content,
# look in /etc/defaults/etc/skel/.bash_profile

# Modifying /etc/skel/.bash_profile directly will prevent
# setup from updating it.

# Guard against re-entrance!
if [ "${BASH_PROFILE_GUARD}" != "__ENTERED_BASH_PROFILE__$(md5sum ${HOME}/.bash_profile)" ]; then
	BASH_PROFILE_GUARD="__ENTERED_BASH_PROFILE__$(md5sum ${HOME}/.bash_profile)"
else
	return
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

# Set PATHs so they include user's private directories if they exist
if [ -d "${HOME}/bin" ] ; then
	PATH="$HOME/bin:$(echo $PATH | sed -re 's!(^|:)'"$HOME"'/bin/?(:|$)!\1!g')"
fi
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/sbin" ]; then
	PATH="$HOME/sbin:$(echo $PATH | sed -re 's!(^|:)'"$HOME"'/sbin/?(:|$)!\1!g')"
fi
# set PATH so it includes sbin if it exists
PATH="$(echo $PATH | sed -re 's!(^|:)/usr/local/sbin/?(:|$)!\1!g' | sed -re 's!(^|:)/usr/sbin/?(:|$)!\1!g' | sed -re 's!(^|:)/sbin/?(:|$)!\1!g'):/usr/local/sbin:/usr/sbin:/sbin"

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

