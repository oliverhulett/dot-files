# shellcheck shell=bash
# Things for the mac.
# N.B.  The craziness with the gnu-utils in /usr/local/bin is covered by the ordering of path in ~/.bashrc
# and some symlink magic in bash_common.sh, because it needs to happen very very early.
# shellcheck disable=SC2155,SC1090

export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
export NVM_DIR="${HOME}/.nvm"
source "$(brew --prefix nvm)/nvm.sh"

export ATLASSIAN_SCRIPTS="${HOME}/src/atlassian/atlassian-scripts/master"
if [ -d "${ATLASSIAN_SCRIPTS}" ]; then
	source "${ATLASSIAN_SCRIPTS}/sourceme.sh"
fi

if [ -e "${HOME}/.sdmake/complete/sdmake.completion.bash" ]; then
	source "${HOME}/.sdmake/complete/sdmake.completion.bash"
fi

export PATH="$(append_path "${PATH}" $(echo "${PATH}" | sed -re 's/:/ /g'))"

# Show metrics collected by sdmake.
export SHOW_DEVMETRICS=true
