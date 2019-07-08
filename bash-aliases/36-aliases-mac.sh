# shellcheck shell=bash
## Mac aliases

function eclipse()
{
	DIR="$1"
	HERE="$(pwd -P)"
	while [ -z "${DIR}" ]; do
		if [ -e "${HERE}/.git" ] || [ -e "${HERE}/.project" ]; then
			DIR="${HERE}"
		elif [ "$HERE" == "/" ]; then
			DIR="$(pwd)"
		else
			HERE="$(dirname "${HERE}")"
		fi
	done
	echo "open /Applications/Eclipse.app" "${DIR}"
	command open /Applications/Eclipse.app "${DIR}"
}

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
