# shellcheck shell=bash
## Atlassian aliases
alias atlas='USER=ohulett atlas'

function rolexer()
{
	curl -L "http://go.atlassian.com/rolex-sprinter"
}

function cid()
{
	for SITE in "$@"; do
		if [ "${SITE##https://}" == "${SITE}" ]; then
			SITE="https://${SITE}"
		fi
		curl "${SITE%%/}/_edge/tenant_info"
	done
}

function sdinfo()
{
	for SITE in "$@"; do
		if [ "${SITE##https://}" == "${SITE}" ]; then
			SITE="https://${SITE}"
		fi
		curl "${SITE%%/}/rest/servicedeskapi/info"
	done
}

function cldurl()
{
	ENV="$1"
	if [ "${ENV}" == "prod" ] || [ "${ENV}" == "stg" ] || [ "${ENV}" == "dev" ] || [ "${ENV}" == "local" ]; then
		shift
	else
		ENV="prod"
	fi
	for SITE in "$@"; do
		governator-cli get-by-cloud-id --cloud-id "${SITE}" --environment "${ENV}" | jq '.cloudUrl'
	done
}

unalias tricorder >/dev/null 2>/dev/null
function tricorder()
{
	#[ -L "${HOME}/npmrc" ] && rm "${HOME}/.npmrc"
	docker pull docker.atl-paas.net/ath
	docker run --rm docker.atl-paas.net/ath | sh
	#"${HOME}/dot-files/setup-home.sh"
}

unalias m2check >/dev/null 2>/dev/null
function m2check()
{
	docker pull docker.atl-paas.net/ath
	docker run --rm docker.atl-paas.net/ath m2check | sh
}

## JMake doesn't like MAVEN_OPTS being set.  :(
#export MAVEN_OPTS="${MAVEN_OPTS} -Djansi.force=true"

function code()
{
	DIR="$1"
	HERE="$(pwd -P)"
	while [ -z "${DIR}" ]; do
		if [ -e "${HERE}/.git" ] || [ -e "${HERE}/.vscode" ]; then
			DIR="${HERE}"
		elif [ "$HERE" == "/" ]; then
			DIR="$(pwd)"
		else
			HERE="$(dirname "${HERE}")"
		fi
	done
	echo "$(command which --skip-function --skip-alias code)" "${DIR}"
	command code "${DIR}"
}
function idea()
{
	DIR=
	VER=
	for a in "$@"; do
		if [ "$a" == "ls" ] || [ "$a" == "list" ]; then
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
				STABLE_VER="$(jq '.version' /Applications/IntelliJ\ IDEA.app/Contents/Resources/product-info.json 2>/dev/null | sed -nre 's/^"([0-9]+.[0-9]).+/\1/p')"
				IDEA_VER="$(echo "${VER}" | sed -nre 's!/Applications/IntelliJ IDEA ([0-9]+.[0-9]) EAP.app!\1!p')"
				if [ -n "${STABLE_VER}" ] && [ -n "${IDEA_VER}" ] && printf '%s\n%s' "${IDEA_VER}" "${STABLE_VER}" | sort -C -V; then
					VER="$(command ls -d /Applications/IntelliJ\ IDEA.app -t1c | head -n1)"
				fi
			elif [ "${a,,}" == "stable" ]; then
				VER="$(command ls -d /Applications/IntelliJ\ IDEA.app -t1c | head -n1)"
			else
				VER="$(command ls -d /Applications/IntelliJ\ IDEA\ "$a"* -t1c 2>/dev/null | head -n1 2>/dev/null)"
			fi
		fi
	done
	if [ -n "$VER" ]; then
		replacelink "${VER}" /Applications/IntelliJ_IDEA.app
		IDEA_VER="$(jq '.version' /Applications/IntelliJ_IDEA.app/Contents/Resources/product-info.json 2>/dev/null | sed -nre 's/^"([0-9]+.[0-9]).+/\1/p')"
		if [ -z "${IDEA_VER}" ]; then
			IDEA_VER="$(echo "${VER}" | sed -nre 's!/Applications/IntelliJ IDEA ([0-9]+.[0-9]) EAP.app!\1!p')"
		fi
		replacelink "$(command ls -d "${HOME}/Library/Preferences/IntelliJIdea${IDEA_VER}" -t1c 2>/dev/null | head -n1 2>/dev/null)" ~/Library/Preferences/IntelliJ_IDEA
		replacelink "$(command ls -d "${HOME}/Library/Caches/IntelliJIdea${IDEA_VER}" -t1c 2>/dev/null | head -n1 2>/dev/null)" ~/Library/Caches/IntelliJ_IDEA
	fi
	HERE="$(pwd -P)"
	while [ -z "${DIR}" ]; do
		if [ -e "${HERE}/.git" ] || [ -e "${HERE}/.idea" ]; then
			DIR="${HERE}"
		elif [ "$HERE" == "/" ]; then
			DIR="$(pwd)"
		else
			HERE="$(dirname "${HERE}")"
		fi
	done
	echo "$(command which --skip-function --skip-alias idea)" "${DIR}"
	command idea "${DIR}"
}

function jira-autocomplete()
{
	mkdir --parents ~/.local/share/bash-completion/completions/
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
