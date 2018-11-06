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
	replacelink "$(command ls -d /Applications/IntelliJ\ IDEA* -t1c | head -n1)" /Applications/IntelliJ_IDEA.app
	replacelink "$(command ls -d /Users/ohulett/Library/Caches/IntelliJIdea*.* -t1c | head -n1)" /Users/ohulett/Library/Caches/IntelliJIdea
	replacelink "$(command ls -d /Users/ohulett/Library/Preferences/IntelliJIdea*.* -t1c | head -n1)" /Users/ohulett/Library/Preferences/IntelliJIdea
	if [ $# -eq 0 ]; then
		set -- .
	fi
	command idea "$@"
}

function jira-autocomplete()
{
	repo jira && ./jmake autocomplete && mv jmake2_completion ~/.jmake/
	echo 'source ~/.jmake/jmake2_completion'
	source ~/.jmake/jmake2_completion
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
