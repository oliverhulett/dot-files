## Useful git environment setup.

GIT_COMPLETE_FILE="/usr/share/git-core/contrib/completion/git-completion.bash"
if [ -e "${GIT_COMPLETE_FILE}" ]; then
	source "${GIT_COMPLETE_FILE}"
else
	GIT_COMPLETE_FILE="${HOME}/etc/git-completion.bash"
	if [ -e "${GIT_COMPLETE_FILE}" ]; then
		source "${GIT_COMPLETE_FILE}"
	fi
fi

GIT_PROMPT_FILE="/usr/share/git-core/contrib/completion/git-prompt.sh"
if [ -e "${GIT_PROMPT_FILE}" ]; then
	source "${GIT_PROMPT_FILE}"
else
	GIT_PROMPT_FILE="${HOME}/etc/git-prompt.sh"
	if [ -e "${GIT_PROMPT_FILE}" ]; then
		source "${GIT_PROMPT_FILE}"
	fi
fi

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWUPSTREAM="auto"

function __custom_git_ps1()
{
	d="$(git branch --no-color 2>/dev/null | sed -nre 's/^\* //p' | cut -d_ -f1)"
	if ( pwd | grep -qw "master" 2>&1 >/dev/null ) || ! ( pwd | grep -qw "$d" 2>&1 >/dev/null ) || [ "$(hostname -s 2>/dev/null)" != "rh5_64-bit_1064-1" ]; then
		__git_ps1 "$@"
	else
		__git_ps1 "$@" "%s" | sed -re 's/(\w+:)?[0-9a-zA-Z_-]+( ?.*)?/\1\2/'
	fi
}

if type -t __git_ps1 >/dev/null 2>&1; then
	# $(__git_ps1) will prepend a space.
	if [ "$TERM" == "cygwin" ]; then
		export PROMPT_FOO="${PROMPT_FOO}"'\[\e[1;34m\]$(__custom_git_ps1 2>/dev/null)\[\e[0m\]'
	else
		export PROMPT_FOO="${PROMPT_FOO}"'\[$(tput bold)\]\[$(tput setaf 4)\]$(__custom_git_ps1 2>/dev/null)\[$(tput sgr0)\]\[$(tput dim)\]'
	fi
fi

