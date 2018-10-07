# shellcheck shell=bash
## Useful git environment setup.

for f in "/etc/bash_completion.d/git-completion.bash" \
		 "/usr/local/etc/bash_completion.d/git-completion.bash" \
		 "/usr/share/git-core/contrib/completion/git-completion.bash" \
		 "${HOME}/etc/git-completion.bash"; do
	if [ -e "$f" ]; then
		source "$f"
		break
	fi
done
for f in "/etc/bash_completion.d/git-prompt" \
		 "/etc/bash_completion.d/git-prompt.sh" \
		 "/usr/local/etc/bash_completion.d/git-prompt.sh" \
		 "/usr/share/git-core/contrib/completion/git-prompt.sh" \
		 "${HOME}/etc/git-prompt.sh"; do
	if [ -e "$f" ]; then
		source "$f"
		break
	fi
done

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWUPSTREAM="auto"

function __custom_git_ps1()
{
	d="$(git branch --no-color 2>/dev/null | sed -nre 's/^\* //p' | cut -d_ -f1 | sed -re 's!^[^/]+/!!')"
	wd="$(pwd | sed -re 's!^'"${HOME}"/?'!!')"
	if grep -qw "master" <(echo $wd) >/dev/null 2>&1 || ! grep -qw "$d" <(echo $wd) >/dev/null 2>&1; then
		__git_ps1 "$@"
	else
		__git_ps1 "$@" "%s" | sed -re 's!(\w+:)?[/0-9a-zA-Z_#-]+( ?.*)?!\1\2!'
	fi
}

if type -t __git_ps1 >/dev/null 2>&1; then
	# $(__git_ps1) will prepend a space.
	if [ "$TERM" == "cygwin" ]; then
		export PROMPT_FOO="${PROMPT_FOO}"'\[\e[1;34m\]$(__custom_git_ps1 2>/dev/null)\[\e[0m\]'
	else
		export PROMPT_FOO="${PROMPT_FOO}"'\[$(tput bold)\]\[$(tput setaf 4)\]$(__custom_git_ps1 2>/dev/null)\[$(tput sgr0)\]'
	fi
fi
