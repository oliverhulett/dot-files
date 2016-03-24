# /home/ols/.bashrc:
# 
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

# Guard against re-entrance!
if [ "${BASHRC_GUARD}" != "__ENTERED_BASHRC__$(cat ${HOME}/.bashrc ${HOME}/.bash_aliases/* 2>/dev/null | md5sum)" ]; then
	BASHRC_GUARD="__ENTERED_BASHRC__$(cat ${HOME}/.bashrc ${HOME}/.bash_aliases/* 2>/dev/null | md5sum)"
else
	return
fi

# source the users profile if it exists
if [ -e "${HOME}/.profile" ] ; then
	source "${HOME}/.profile"
fi

# source the users bash_profile if it exists
if [ -e "${HOME}/.bash_profile" ] ; then
	source "${HOME}/.bash_profile"
fi

if [ -z "$REAL_WHICH" ]; then
	## Happy to clobber this here, we will re-read .bash_aliases below.
	REAL_WHICH="$(which --skip-alias --skip-functions --skip-dot --skip-tilde which 2>/dev/null) --skip-alias --skip-functions --skip-dot --skip-tilde"
	if ! $REAL_WHICH which 2>/dev/null >/dev/null; then
		if [ -x /bin/which ]; then
			REAL_WHICH=/bin/which
		elif [ -x /usr/bin/which ]; then
			REAL_WHICH=/usr/bin/which
		else
			REAL_WHICH=which
		fi
	fi
fi

export VISUAL=$($REAL_WHICH vim)
export EDITOR=$VISUAL
export PAGER=$($REAL_WHICH less)
alias edt=$VISUAL

export HISTCONTROL="ignoredups"
export HISTIGNORE="[   ]*:&:bg:fg:sh:exit"
unset HISTFILESIZE
export HISTSIZE=10000

function set_local_paths()
{
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

	# Do any profile setup
	shopt -s nullglob
	for p in ${HOME}/.bash_aliases/profile.d-*.sh; do
		source "$p"
	done
}

set_local_paths

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]]; then
	# Shell is non-interactive.  Be done now
	return
fi

# Shell is interactive.  It is okay to produce output at this point,
# though this example doesn't produce any.  Do setup for
# command-line interactivity.

# colors for ls, etc.  Prefer "$HOME/.dir_colors" #64489
if type -f dircolors >/dev/null 2>&1; then
	if [ -f "$HOME/.dir_colors" ]; then
		eval `dircolors -b "$HOME/.dir_colors"`
	elif [ -f "/etc/DIR_COLORS" ]; then
		eval `dircolors -b /etc/DIR_COLORS`
	fi
fi

# Use VI mode editing
set -o vi

# Don't wait for job termination notification
set -o notify

# Don't use ^D to exit
#set -o ignoreeof

# Use case-insensitive filename globbing
# shopt -s nocaseglob

# Make bash append rather than overwrite the history on disk
shopt -s histappend

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

##	Get real (pathed) versions of commands we will later replace with aliases or functions.
##	TODO:  Handle executable paths with spaces and executable names with spaces.
function get_real_exe()
{
	exe="$1"
	for f in $(type -fa $exe 2>/dev/null | sed -re 's/[^ ]+ is (.+)$/\1/'); do
		if [ -x "$f" ]; then
			eval export REAL_$(echo $exe | tr '[a-z]' '[A-Z]')="$f"
			alias real_${exe}="$f"
			echo "$f"
			break
		fi
	done
}
REAL_CAT=/bin/cat
REAL_WHICH=/bin/which
REAL_LS=/bin/ls
for exe in ls cat which; do
	get_real_exe $exe >/dev/null
done
export REAL_CAT REAL_WHICH REAL_LS

# We can clear some variables here that will be set/updated by the bash_aliases includes and used later.
export PROMPT_FOO=
export PROMPT_COMMAND=

if [ -d "$HOME/.bash_aliases" ]; then
	for f in $HOME/.bash_aliases/*; do
		source "$f"
	done
elif [ -r "$HOME/.bash_aliases" ]; then
	source "$HOME/.bash_aliases"
fi

set_local_paths

# Two stage command to remember $OLDPWD.
OLDPWD_FILE="$HOME/.oldpwd"
# Trap EXIT and write `pwd` to a file.
trap 'if [ "`pwd`" == "$HOME" ] && [ -n "$OLDPWD" ] && [ "$OLDPWD" != "$HOME" ]; then echo $OLDPWD >"$OLDPWD_FILE"; else pwd >"$OLDPWD_FILE"; fi;' EXIT
# If `pwd` was written to a file last time, restore directory into $OLDPWD.
if [ -f "$OLDPWD_FILE" ]; then
	export OLDPWD=`$REAL_CAT $OLDPWD_FILE 2>/dev/null`
fi

# uncomment the following to activate bash-completion:
COMP_CONFIGURE_HINTS=1
COMP_TAR_INTERNAL_PATHS=1
[ -f /etc/profile.d/bash-completion ] && source /etc/profile.d/bash-completion

# enable programmable completion features (you don't need to enable this if it's already enabled
# in /etc/bash.bashrc and /etc/profile sources /etc/bash.bashrc
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
	. /etc/bash_completion
fi

# Change the window title of X terminals
case $TERM in
	xterm*|rxvt*|Eterm)
		PROMPT_COMMAND='echo -ne "\n\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"'
		;;
	screen)
		PROMPT_COMMAND='echo -ne "\n\033_${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\033\\"'
		;;
esac
# Whenever displaying the prompt, write the previous line to disk
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

if [ "$TERM" == "cygwin" ]; then
	PS1='\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\]'"${PROMPT_FOO}"'\n\$ '
elif [ -z "${HOSTNAME/op??nxsr[0-9][0-9][0-9][0-9]*}" ]; then
	PS1='\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\]'"${PROMPT_FOO}"' \$ '
else
	PS1='\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]'"${PROMPT_FOO}"' \$ '
fi
export PS1

