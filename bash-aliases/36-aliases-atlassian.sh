# shellcheck shell=bash
## Atlassian aliases
alias atlas='USER=ohulett atlas'
alias atlas-docker-login='cat ~/etc/artifactory-api-key.txt | docker login --username ohulett --password-stdin docker.atl-paas.net'

function rolexer()
{
	curl -L "http://go.atlassian.com/rolex-sprinter"
}

function _curl_per_site()
{
	URL="$1"
	shift
	for SITE in "$@"; do
		if [ "${SITE##https://}" == "${SITE}" ]; then
			SITE="https://${SITE}"
		fi
		echo -n "${SITE%%/} : "
		curl -s "${SITE%%/}${URL}" | jq .
		echo
	done
}

function cid()
{
	_curl_per_site /_edge/tenant_info "$@"
}
alias cldid=cid

function sdinfo()
{
	_curl_per_site /rest/servicedeskapi/info "$@"
}

function _governator_per_cid()
{
	ENV="$1"
	if [ "${ENV}" == "prod" ] || [ "${ENV}" == "stg" ] || [ "${ENV}" == "dev" ] || [ "${ENV}" == "local" ]; then
		shift
	else
		ENV="prod"
	fi
	for CID in "$@"; do
		USER=ohulett governator-cli get-by-cloud-id --cloud-id "${CID}" --environment "${ENV}"
	done
}

function cldurl()
{
	JQFILTER=
	JQFILTER="${JQFILTER}"'"-----",'
	JQFILTER="${JQFILTER}"'"CID: " + .cloudId,'
	JQFILTER="${JQFILTER}"'"URL: " + .cloudUrl,'
	JQFILTER="${JQFILTER}"'"-----"'
	_governator_per_cid "$@" | jq "${JQFILTER}"
}

function cldinfo()
{
	JQFILTER=
	JQFILTER="${JQFILTER}"'"---------",'
	JQFILTER="${JQFILTER}"'"CID    : " + .cloudId,'
	JQFILTER="${JQFILTER}"'"URL    : " + .cloudUrl,'
	JQFILTER="${JQFILTER}"'"SHARD  : " + .jiraShard.name,'
	JQFILTER="${JQFILTER}"'"MONARCH: " + .jiraMonarchInstanceId,'
	JQFILTER="${JQFILTER}"'"SPLUNK : " + .jiraSplunkLink,'
	JQFILTER="${JQFILTER}"'"---------"'
	_governator_per_cid "$@" | jq "${JQFILTER}"
}

function issueid()
{
	ENV="$1"
	if [ "${ENV}" == "prod" ] || [ "${ENV}" == "staging" ] || [ "${ENV}" == "dev" ]; then
		shift
	else
		ENV="prod"
	fi
	GOV="https://governator.${ENV}.atl-paas.net/api/1/sis/query/run"
	URL="$1"
	if [ "${URL##https://}" == "${URL}" ]; then
		URL="https://${URL}"
	fi
	shift
	QUERY="select pkey, issuenum, id from jiraissue where"
	first="true"
	for ik in "$@"; do
		PKEY="${ik%-*}"
		INUM="${ik##*-}"
		if [ "${first}" == "false" ]; then
			QUERY="${QUERY} or"
		fi
		QUERY="${QUERY} (pkey = '${PKEY}' and issuenum = '${INUM}')"
		first="false"
	done
	echo USER=ohulett atlas slauth curl --env "${ENV}" --aud=governator --mfa -- -s "${GOV}" -H "Content-Type: application/json" -X POST -d "{\"query\":\"${QUERY}\",\"hostname\":\"${URL}\"}"
	echo "pkey, issuenum, id"
	USER=ohulett atlas slauth curl --env "${ENV}" --aud=governator --mfa -- -s "${GOV}" -H "Content-Type: application/json" -X POST -d "{\"query\":\"${QUERY}\",\"hostname\":\"${URL}\"}" | jq .rows | jq '.[] | (.items[0].value + ", " + .items[1].value + ", " + .items[2].value)'
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

function whereismycommit()
{
	if [ $# -eq 0 ]; then
		repo jira || ( echo "go/whereismycommit only works for Jira.  Can't cd into Jira repo"; return 1 )
		git pullme
		echo
		echo "Using your last committed hash as argument to go/whereismycommit"
		HASH="${1:-$(git mylasthash --merges master)}"
		git log "${HASH}^!"
		set -- "${HASH}"
		cd - >/dev/null || return 1
	fi
	for HASH in "$@"; do
		echo
		echo "go/whereismycommit ${HASH}"
		curl "https://commit-tracker-service.us-east-1.prod.atl-paas.net/commit/jira/hash?filter=${HASH}" | jq .
	done
}

function jira-blockers()
{
	curl 'https://commit-tracker-service.us-east-1.prod.atl-paas.net/blockers/jira' | jq .
}
