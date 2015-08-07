# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Guard against re-entrance!
if [ "${PROFILE_GUARD}" != "__ENTERED_PROFILE__$(md5sum ${HOME}/.profile)" ]; then
	PROFILE_GUARD="__ENTERED_PROFILE__$(md5sum ${HOME}/.profile)"
else
	return
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
	if [ -e "$HOME/.bash_profile" ]; then
		# include .bash_profile if it exists
		. "$HOME/.bash_profile"
	elif [ -e "$HOME/.bashrc" ]; then
		# include .bashrc if it exists
		. "$HOME/.bashrc"
	fi
fi

