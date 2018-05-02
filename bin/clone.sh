#!/bin/bash
## Clone a repository, and put it in the right place.

## Potential servers are stash.atlassian.com, bitbucket.org, github.com
STASH="ssh://git@stash.atlassian.com:7997/"
BITBUCKET="git@bitbucket.org:"
GITHUB="https://github.com/"
SERVERS=( "$STASH" "$BITBUCKET" "$GITHUB" )

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$(dirname ${HERE})/lib/script_utils.sh"

function print_usage()
{
	echo "$(basename -- "$0") [-a] [-s <server>] <project> <repo>"
	echo "  Clone a repository into the correct place and do some project setup things..."
	echo "  -a  Check all servers and report ambiguous repositories."
	echo "  -s  Checkout from the given server."
}

OPTS=$(getopt -o "has:" --long "help,all,server:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	print_usage >&2
	exit $es
fi

CHECK_ALL="false"
SERVER=
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			print_usage
			exit 0
			;;
		-a | --all )
			CHECK_ALL="true"
			shift
			;;
		-s | --server )
			shift
			case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
				"stash" | "stash.atlassian.com" | "sac" | "s" )
					SERVER="${STASH}"
					;;
				"bitbucket" | "bitbucket.org" | "bb" | "b" )
					SERVER="${BITBUCKET}"
					;;
				"github" | "github.com" | "gh" | "g" )
					SERVER="${GITHUB}"
					;;
				"*" )
					echo >&2 "Unknown server: $1"
					print_usage >&2
					exit 1
			esac
			shift
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

function run_and_tell()
{
	report_neutral "$1"
	shift
	report_cmd "$@"
}

if [ $# -ne 2 ]; then
	print_usage >&2
	exit 1
fi

PROJ="$1"
REPO="$2"

function test_server()
{
	if run_and_tell "Testing $1 for $2/$3" git ls-remote "$1$2/$3.git" dummy 2>/dev/null; then
		if [ -z "${SERVER}" ]; then
			SERVER="$1"
			report_good "Found server for $2/$3: $SERVER"
		else
			report_bad "Ambiguous repository exists in more than one server: $SERVER and $1 (Using $SERVER)"
		fi
	elif run_and_tell "Maybe it's a personal repo.  Testing $1 for ~$2/$3" git ls-remote "$1~$2/$3.git" dummy 2>/dev/null; then
		if [ -z "${SERVER}" ]; then
			SERVER="$1"
			PROJ="~$2"
			report_good "Found server for $2/$3: $SERVER"
		else
			report_bad "Ambiguous repository exists in more than one server: $SERVER and $1 (Using $SERVER and $PROJ)"
		fi
	fi
}

if [ -z "${SERVER}" ]; then
	for s in "${SERVERS[@]}"; do
		test_server "$s" "$1" "$2"
		if [ "$CHECK_ALL" == "false" ] && [ -n "$SERVER" ]; then
			break
		fi
	done
else
	# Forces us to check that the given server has the requested repository.  Also tricks PROJ into getting the tilde if appropriate.
	s="$SERVER"
	SERVER=
	test_server "$s" "$1" "$2"
fi
echo

if [ -z "$SERVER" ]; then
	report_bad "Failed to find an appropriate server for $1/$2."
	exit 1
fi

ROOT="${HOME}/repo"
if [ "$SERVER" == "$GITHUB" ]; then
	ROOT="${HOME}/src"
fi
CHECKOUT_PATH="${ROOT}/$(echo "$1" | tr '[:upper:]' '[:lower:]')/$(echo "$2" | tr '[:upper:]' '[:lower:]')"

if [ -d "${CHECKOUT_PATH}/master" ]; then
	report_good "There is already something checked out for $1/$2 at ${CHECKOUT_PATH}/master"
	exit 0
fi

run_and_tell "Making repository directory: ${CHECKOUT_PATH}" mkdir --parents "${CHECKOUT_PATH}"
cd "${CHECKOUT_PATH}" && run_and_tell "Cloning $1/$2 from $SERVER" git clone --recursive "${SERVER}${PROJ}/${REPO}.git" master
get-repo-dir.sh "$1" "$2"
