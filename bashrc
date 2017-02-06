# /home/ols/.bashrc:
# 
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

source "${HOME}/dot-files/bash_common.sh"
if reentered "${HOME}/.bashrc" "${HOME}/.bash_aliases"/*; then
	return 0
fi

# source the users profile if it exists
if [ -e "${HOME}/.profile" ] ; then
	source "${HOME}/.profile"
fi

# source the users bash_profile if it exists
if [ -e "${HOME}/.bash_profile" ] ; then
	source "${HOME}/.bash_profile"
fi

export VISUAL=$(command which vim 2>/dev/null)
export EDITOR=$VISUAL
export PAGER=$(command which less 2>/dev/null)
alias edt=$VISUAL

export HISTCONTROL="ignoredups"
export HISTIGNORE="[   ]*:&:bg:fg:sh:exit:history"
unset HISTFILESIZE
export HISTSIZE=10000

function set_local_paths()
{
	shopt -s nullglob
	for p in $(echo ${HOME}/.bash_aliases/*-profile.d-* | sort -n); do
		source "$p"
	done
	unset p
	if [ -d "${HOME}/bin" ]; then
		export PATH="$(prepend_path "${HOME}/bin")"
	fi
	if [ -d "$HOME/sbin" ]; then
		export PATH="$(prepend_path "${HOME}/sbin")"
	fi
	export PATH="$(append_path /usr/local/sbin /usr/sbin /sbin)"
	shopt -u nullglob
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
		eval `dircolors -b "$HOME/.dir_colors" 2>/dev/null` 2>/dev/null
	elif [ -f "/etc/DIR_COLORS" ]; then
		eval `dircolors -b /etc/DIR_COLORS 2>/dev/null` 2>/dev/null
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
# Make bash show timestamp of executed command when showing history
export HISTTIMEFORMAT='%F %T '

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
shopt -s cdspell

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# We can clear some variables here that will be set/updated by the bash_aliases includes and used later.
export PROMPT_FOO=
export PROMPT_COMMAND=":"

if [ -d "$HOME/.bash_aliases" ]; then
	for f in $(echo $HOME/.bash_aliases/* | sort -n); do
		source "$f"
	done
	unset f
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
	export OLDPWD=`command cat $OLDPWD_FILE 2>/dev/null`
fi

# uncomment the following to activate bash-completion:
COMP_CONFIGURE_HINTS=1
COMP_TAR_INTERNAL_PATHS=1
[ -f /etc/profile.d/bash-completion ] && . /etc/profile.d/bash-completion
[ -f /etc/profile.d/bash-completion.sh ] && . /etc/profile.d/bash-completion.sh
[ -f /etc/profile.d/bash_completion.sh ] && . /etc/profile.d/bash_completion.sh
[ -f /etc/profile.d/bash_completion ] && . /etc/profile.d/bash_completion
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

# Whenever displaying the prompt, show the run-time of last command
unset _timer
_timer_show=0
function _timer_start()
{
	_timer=${_timer:-$SECONDS}
}
function _timer_stop()
{
	_timer_show=$(($SECONDS - $_timer))
	unset _timer
}
trap '_timer_start' DEBUG
# _timer_stop has to be at the end of PROMPT_COMMAND otherwise you'll be timing from the next PROMPT_COMMAND command
PROMPT_COMMAND="$PROMPT_COMMAND; _timer_stop"
function _last_cmd_interactive()
{
	set -- `history 1`
	# `history` outputs command count, then date, then time, then command
	shift 3
	grep -qwE "$(sed -re 's/^\^?/^/' ${HOME}/.interactive_commands 2>/dev/null | paste -sd'|' -)" <(echo "$@") >/dev/null 2>/dev/null
}

PROMPT_TIMER='$(if [ "$_timer_show" -gt 1 ] && ! _last_cmd_interactive; then echo '"'['"'${_timer_show}s'"'] '"'; fi)'
PROMPT_EXIT='$(es=$?; if [ $es -eq 0 ]; then echo :\); else echo :\(; fi)'
if [ "$TERM" == "cygwin" ]; then
	PS1="${PROMPT_PREFIX}"'\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\] '"${PROMPT_TIMER}${PROMPT_EXIT}${PROMPT_FOO}"'\n\$ '
elif [ -z "${HOSTNAME/op??nxsr[0-9][0-9][0-9][0-9]*}" ]; then
	PS1="${PROMPT_PREFIX}"'\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\] '"${PROMPT_TIMER}${PROMPT_EXIT}${PROMPT_FOO}"' \$ '
else
	PS1="${PROMPT_PREFIX}"'\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\] '"${PROMPT_TIMER}${PROMPT_EXIT}${PROMPT_FOO}"' \$ '
fi
export PS1

