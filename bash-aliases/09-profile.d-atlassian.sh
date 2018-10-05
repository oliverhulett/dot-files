# shellcheck shell=bash
# Things for the mac.
# shellcheck disable=SC2155,SC1090

if reentered "${HOME}/.bash-aliases/09-profile.d-atlassian.sh"; then
	return 0
fi

export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
export NVM_DIR="${HOME}/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

export ATLASSIAN_SCRIPTS="${HOME}/repo/atlassian/atlassian-scripts/master"
if [ -d "${ATLASSIAN_SCRIPTS}" ]; then
	source "${ATLASSIAN_SCRIPTS}/sourceme.sh"
fi

if [ -e "${HOME}/.sdmake/complete/sdmake.completion.bash" ]; then
	source "${HOME}/.sdmake/complete/sdmake.completion.bash"
fi

if [ -e "${HOME}/.jmake/jmake2_completion" ]; then
	source "${HOME}/.jmake/jmake2_completion"
fi

export PATH="$(append_path "${PATH}" $(echo "${PATH}" | sed -re 's/:/ /g'))"

# Show metrics collected by volt.
export SHOW_DEVMETRICS=false
