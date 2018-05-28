# shellcheck shell=bash
## Atlassian aliases
alias tricorder='docker pull docker.atl-paas.net/ath; docker run --rm docker.atl-paas.net/ath | sh'

export MAVEN_OPTS="${MAVEN_OPTS} -Djansi.force=true"
