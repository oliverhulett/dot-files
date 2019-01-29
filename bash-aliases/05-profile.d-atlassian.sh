# shellcheck shell=bash
# Things for the mac.
# shellcheck disable=SC2155,SC1090

if reentered "${HOME}/.bash-aliases/05-profile.d-atlassian.sh"; then
	return 0
fi

export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
export NVM_DIR="${HOME}/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

export JIRA_HOME="$(get-repo-dir.sh jiracloud jira master)"

export ATLASSIAN_SCRIPTS="${HOME}/repo/atlassian/atlassian-scripts/master"
if [ -d "${ATLASSIAN_SCRIPTS}" ]; then
	source "${ATLASSIAN_SCRIPTS}/sourceme.sh"
fi

if [ -e "${HOME}/.local/share/bash-completion/completions/jmake" ]; then
	source "${HOME}/.local/share/bash-completion/completions/jmake"
	complete -F _complete_jmake -o default ./jmake jmake
fi

export PATH="$(append_path "${PATH}" $(echo "${PATH}" | sed -re 's/:/ /g'))"

# Show metrics collected by volt.
export SHOW_DEVMETRICS=false
