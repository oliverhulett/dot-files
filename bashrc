# shellcheck shell=bash
# /home/ols/.bashrc:
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.

export PATH="${PATH:-/usr/local/bin:/usr/bin:/bin}"
source "${HOME}/dot-files/bash_common.sh"
export PATH="$(append_path "/bin" "/usr/bin")"
if reentered "${HOME}/.bashrc" "${HOME}/.bash_aliases"/*; then
	return 0
fi

# source the users profile if it exists
if [ -e "${HOME}/.profile" ]; then
	source "${HOME}/.profile"
fi

# source the users bash_profile if it exists
if [ -e "${HOME}/.bash_profile" ]; then
	source "${HOME}/.bash_profile"
fi

#export BASH_ENV="${HOME}/.bashrc"

export VISUAL=vim
export EDITOR=vim
export PAGER=less
function vim()
{
	source "${HOME}/dot-files/bash_common.sh" 2>/dev/null || true
	VUNDLE_LAST_UPDATED_MARKER="${HOME}/.vim/bundle/.last_updated"
	if [ -z "$(find "${VUNDLE_LAST_UPDATED_MARKER}" -mtime -1 2>/dev/null)" ] || \
		[ "$(command grep -P '^[ \t]*Plugin ' "${HOME}/.vimrc" | xargs -L1 | sort)" != "$(tail -n +2 "${VUNDLE_LAST_UPDATED_MARKER}")" ]; then
		[ -e "${HOME}/.bash_aliases/49-setup-proxy.sh" ] && source "${HOME}/.bash_aliases/49-setup-proxy.sh" 2>/dev/null
		command vim +'silent! PluginInstall' +qall
		date >"${VUNDLE_LAST_UPDATED_MARKER}"
		command grep -P '^[ \t]*Plugin ' "${HOME}/.vimrc" | xargs -L1 | sort >>"${VUNDLE_LAST_UPDATED_MARKER}"
	fi
	command vim "${VUNDLE_UPDATE_CMDS[@]}" "$@"
	es=$?
	log "Command=vim Seconds=$((SECONDS - _timer)) Returned=$es CWD=$(pwd) Files={$*}"
	return $es
}
alias edt=vim

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
	export PATH="$(prepend_path "${HOME}/dot-files/bin")"
	export PATH="$(append_path /usr/local/sbin /usr/sbin /sbin)"
	shopt -u nullglob
}

set_local_paths >/dev/null 2>/dev/null

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
		eval "$(dircolors -b "$HOME/.dir_colors" 2>/dev/null)" 2>/dev/null
	elif [ -f "/etc/DIR_COLORS" ]; then
		eval "$(dircolors -b /etc/DIR_COLORS 2>/dev/null)" 2>/dev/null
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
trap -n oldpwd 'if [ "`pwd`" == "$HOME" ] && [ -n "$OLDPWD" ] && [ "$OLDPWD" != "$HOME" ]; then echo $OLDPWD >"$OLDPWD_FILE"; else pwd >"$OLDPWD_FILE"; fi;' EXIT
# If `pwd` was written to a file last time, restore directory into $OLDPWD.
if [ -f "$OLDPWD_FILE" ]; then
	export OLDPWD=$(command cat $OLDPWD_FILE 2>/dev/null)
fi

# uncomment the following to activate bash-completion:
export COMP_CONFIGURE_HINTS=1
export COMP_TAR_INTERNAL_PATHS=1
[ -f /etc/profile.d/bash-completion ] && source /etc/profile.d/bash-completion
[ -f /etc/profile.d/bash-completion.sh ] && source /etc/profile.d/bash-completion.sh
[ -f /etc/profile.d/bash_completion.sh ] && source /etc/profile.d/bash_completion.sh
[ -f /etc/profile.d/bash_completion ] && source /etc/profile.d/bash_completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

# Whenever displaying the prompt, show the run-time of last command.
# We do this by with a variable _timer, which is initially unset.
# The function _timer_start will set _timer iff _timer is currently unset.
# It is installed as a DEBUG handler, so will be triggered before each command.
# _timer will be unset by PROMPT_COMMAND.
unset _timer
function _timer_start()
{
	_timer=${_timer:-$SECONDS}
}
builtin trap '_timer_start' DEBUG

function _prompt_command()
{
	local _last_exit_status=$?

	eval "${_hidex}"

	# Whenever displaying the prompt, write the previous line to disk
	history -a

	if [ "$TERM" == "cygwin" ]; then
		PROMPT_COLOUR='\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\]'
		PROMPT_DOLLAR='\n\$'
	elif [ -z "${HOSTNAME/op??nx??[0-9][0-9][0-9][0-9]*}" ]; then
		PROMPT_COLOUR='\[\e[31m\]\u@\h \[\e[33m\]\w\[\e[0m\]'
		PROMPT_DOLLAR='\$'
	else
		PROMPT_COLOUR='\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]'
		PROMPT_DOLLAR='\$'
	fi

	# At the start of the prompt command, remember the exit status of the last command
	if [ $_last_exit_status -eq 0 ]; then
		PROMPT_EXIT=':)'
	else
		PROMPT_EXIT=':('
	fi

	# Calculate the run-time of the last command
	local _timer_show=$((SECONDS - _timer))
	unset _timer

	# Only display run-time of last command if it is greater than 1 second and not an interactive command
	PROMPT_TIMER=
	if [ ${_timer_show-0} -gt 1 ]; then
		set -- $(history 1)
		# `history` outputs command count, then date, then time, then command
		shift 3
		if ! grep -qwE "$(sed -re 's/^\^?/^/' ${HOME}/.interactive_commands 2>/dev/null | paste -sd'|' -)" <(echo "$@") >/dev/null 2>/dev/null; then
			PROMPT_TIMER='['
			if [ ${_timer_show} -ge 3600 ]; then
				PROMPT_TIMER="${PROMPT_TIMER}$((_timer_show / 3600))h"
				_timer_show=$((_timer_show % 3600))
				if [ ${_timer_show} -lt 60 ]; then
					PROMPT_TIMER="${PROMPT_TIMER}0m"
				fi
			fi
			if [ ${_timer_show} -ge 60 ]; then
				PROMPT_TIMER="${PROMPT_TIMER}$((_timer_show / 60))m"
				_timer_show=$((_timer_show % 60))
			fi
			PROMPT_TIMER="${PROMPT_TIMER}${_timer_show}s"'] '
		fi
	fi

	PROMPT="${PROMPT_COLOUR} ${PROMPT_TIMER}${PROMPT_EXIT}${PROMPT_FOO} ${PROMPT_DOLLAR} "

	if echo $PS1 | command grep -q '\\' >/dev/null 2>/dev/null || echo $PS1 | command grep -q '\$' >/dev/null 2>/dev/null; then
		# If it looks like a prompt, we're going to replace it...
		USER_CUSTOM_FRONT="$(echo $PS1 | sed -nre "s!(.*)$(printf "%q" "${PROMPT_COLOUR}").*!\1!p")"
	else
		# ...otherwise we'll use it as a custom prefix.
		USER_CUSTOM_FRONT="$PS1"
	fi
	export PS1="${USER_CUSTOM_FRONT}${PROMPT}"
	printf '%*s\n' ${COLUMNS} "$(date)"
	eval "${_restorex}"
}
export PROMPT_COMMAND=_prompt_command
