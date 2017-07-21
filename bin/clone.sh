#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

GIT_URL_BASE="ssh://git@git.comp.optiver.com:7999"
REPO_DIR="${HOME}/repo"

function print_help()
{
	echo "$(basename -- "$0") [-h|-?|--help]"
	echo "$(basename -- "$0") [--cpp|--go|--py[thon]] <REPOSITORY> <PROJECT>"
	echo "  --cpp:          Treat cloned project as a C++ project,"
	echo "  --go:           Treat cloned project as a C++ project,"
	echo "  --py --python:  Treat cloned project as a python project,"
	echo "    Otherwise, attempt to detect the project type from the cloned files."
	echo "  <REPOSITORY> <PROJECT>:  The repo a project parts of the git URL to clone, omit the '.git' suffix"
}

OPTS=$(getopt -o "h" --long "help,cpp,go,py,python" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_help
	exit $es
fi

PROJ_TYPE=
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_help;
			exit 0;
			;;
		--cpp )
			PROJ_TYPE="cpp"
			shift
			;;
		--go )
			PROJ_TYPE="go"
			shift
			;;
		--py | --python )
			PROJ_TYPE="python"
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

if [ $# -eq 2 ]; then
	PROJ="$(echo $1 | tr '[:upper:]' '[:lower:]' | tr ' ' -)"
	REPO="$(echo $2 | tr '[:upper:]' '[:lower:]' | tr ' ' -)"
else
	echo 2>/dev/null "Clone a repo into the repo heirarchy"
	echo 2>/dev/null "$(basename -- "$0") <PROJECT> <REPOSITORY>"
	exit 1
fi

GIT_URL="${GIT_URL_BASE}/${PROJ}/${REPO}.git"
DEST_DIR="${REPO_DIR}/${PROJ##\~}/${REPO}"

mkdir --parents "${DEST_DIR}"
pushd "${DEST_DIR}" 2>/dev/null >/dev/null

function cleanup()
{
	popd 2>/dev/null >/dev/null
	rmdir --parents "${DEST_DIR}/master" 2>/dev/null || true
	rmdir --parents "${DEST_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

if [ ! -d "${DEST_DIR}/master" ]; then
	echo "Cloning ${GIT_URL}"
	git clone --recursive "${GIT_URL}" master || exit $?
	( cd master && git update )
else
	echo "${DEST_DIR}/master already exists."
fi

if [ ! -e "${DEST_DIR}/.project" ]; then
	ECLIPSE_PROJECT_FILES="${DOTFILES}/eclipse-project-files"
	if [ "${PROJ_TYPE}" == "cpp" ] || [ -e "master/CMakeLists.txt" ]; then
		## C++ project
		cp -rv "${ECLIPSE_PROJECT_FILES}/cpp/".[a-z]* ./
	elif [ "${PROJ_TYPE}" == "go" ] || [ -d "master/src" ]; then
		## GO project
		cp -rv "${ECLIPSE_PROJECT_FILES}/go/".[a-z]* ./
	else
		## Fallback to python project.  Most projects will have some python anyway.
		cp -rv "${ECLIPSE_PROJECT_FILES}/python/".[a-z]* ./
	fi
	sed -re 's!<name>.+@master</name>!<name>'"${REPO}"'@master</name>!' .project -i 2>/dev/null
fi
if [ ! -e "${DEST_DIR}/master/.project" ]; then
	( cd master && ln -sv ../.[a-z]* ./ )
fi
