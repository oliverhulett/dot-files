# shellcheck shell=bash
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export PATH="${PATH:-/bin:/usr/bin}"
source "${HOME}/dot-files/bash_common.sh"
export PATH="$(append_path "${PATH}" "/usr/local/bin" "/usr/bin" "/bin")"
if reentered "${HOME}/.profile"; then
	return 0
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
	if [ -e "$HOME/.bash_profile" ]; then
		# include .bash_profile if it exists
		source "$HOME/.bash_profile"
	elif [ -e "$HOME/.bashrc" ]; then
		# include .bashrc if it exists
		source "$HOME/.bashrc"
	fi
fi
