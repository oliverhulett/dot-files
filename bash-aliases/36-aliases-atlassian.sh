# shellcheck shell=bash
## Atlassian aliases
alias tricorder='docker pull docker.atl-paas.net/ath; docker run --rm docker.atl-paas.net/ath | sh'
alias vgrok='ngrok start jira-exploratory-development &'
## Actually run vgrok so that it is "always" running
( exec >/dev/null 2>/dev/null; vgrok )

## JMake doesn't like MAVEN_OPTS being set.  :(
#export MAVEN_OPTS="${MAVEN_OPTS} -Djansi.force=true"

function idea()
{
	DIR=
	VER=
	for a in "$@"; do
		if [ "$a" == "ls" ]; then
			lsl -d {/Applications,~/Library/Preferences,~/Library/Caches}/IntelliJ*
			return
		fi
		if [ -z "${DIR}" ] && [ -d "$a" ]; then
			DIR="$a"
			continue
		fi
		if [ -z "$VER" ]; then
			if [ "${a,,}" == "latest" ]; then
				VER="$(command ls -d /Applications/IntelliJ\ IDEA* -t1c 2>/dev/null | head -n1 2>/dev/null)"
			elif [ "${a,,}" == "stable" ]; then
				VER="$(command ls -d /Applications/IntelliJ\ IDEA.app -t1c | head -n1)"
			else
				VER="$(command ls -d /Applications/IntelliJ\ IDEA\ "$a"* -t1c 2>/dev/null | head -n1 2>/dev/null)"
			fi
		fi
	done
	if [ -n "$VER" ]; then
		replacelink "${VER}" /Applications/IntelliJ_IDEA.app
	fi
	if [ -z "${DIR}" ]; then
		DIR="$(pwd -P)"
	fi
	echo "$(command which --skip-function --skip-alias idea)" "${DIR}"
	command idea "${DIR}"
}

function jira-autocomplete()
{
	repo jira && ./jmake autocomplete --force --output ~/.local/share/bash-completion/completions/jmake
	echo 'source ~/.local/share/bash-completion/completions/jmake'
	source ~/.local/share/bash-completion/completions/jmake
}

function jira-deps()
{
	repo jira && mvn dependency:resolve -U
}

function jira-released()
{
	repo jira || return 1
	git pullme
	echo
	echo "Re-basing vertigo-release"
	( repo jira vertigo-release && git pullme ) >/dev/null 2>/dev/null
	echo "Re-basing vertigo-prod"
	( repo jira vertigo-prod && git pullme ) >/dev/null 2>/dev/null
	echo
	HASH="${1:-$(git mylasthash)}"
	git log "${HASH}^!"
	echo
	echo "Branches containing ${HASH}"
	git branch --contains "${HASH}"
	cd - >/dev/null || return 1
}
