#!/bin/bash
set -e

if [ $# -ne 1 -o "$1" == "-h" -o "$1" == "-?" ]; then
	echo 1>&2 "$(basename -- "$0") requires a bit-file image to flash."
	echo 1>&2 "$(basename -- "$0") <bitfile>"
	exit 1
fi
ARTIFACT="$1"
shift

DEPLOY_TOOLS="https://artifactory/artifactory/dev/fpga/deploy_tools/1.0.1/1.0.1_deploy-tools.tar.gz"

LVLS=0
function pushd()
{
	LVLS=$(( $LVLS + 1 ))
	builtin pushd "$@"
}

function run()
{
	for cmd in 'echo $ ' ""; do
		$cmd "$@"
	done
}

SCRATCH="$(mktemp -d)"
function cleanup()
{
	for (( i=0; i < $LVLS; i=$(( $i + 1 )) )); do
		popd
	done
	rm -rf "${SCRATCH}"
}
trap cleanup EXIT
pushd "${SCRATCH}"

run wget --no-check-certificate --no-verbose "${DEPLOY_TOOLS}"
run tar -xzvf "$(basename -- "${DEPLOY_TOOLS}")"
if [ "${ARTIFACT#http}" == "${ARTIFACT}" ]; then
	BITFILE="${ARTIFACT}"
else
	BITFILE="$(basename -- "${ARTIFACT}")"
	if [ ! -e "${BITFILE}" ]; then
		run wget --no-check-certificate --no-verbose "${ARTIFACT}"
	fi
fi
if [ "${BITFILE%.bit}" == "${BITFILE}" ]; then
	tar -xzvf "${BITFILE}"
	BITFILE="$(tar -tf "${BITFILE}")"
fi

echo "## About to flash the board.  If anyone asks, you're targeting board: fex_fb"
#echo "fex_fb" | run sudo "${DEPLOY_DIR}/flash_tool.py" "${BITFILE}"
run sudo "${SCRATCH}/flash_tool.py" "${BITFILE}"

if [ $? -ne 0 ]; then
	echo "## Failed to write the bitfile from '${ARTIFACT}'"
	echo "## If the error is related to not being able to find 'rmmod', you need to add '/sbin:/usr/sbin' to the 'secure_path' of your sudoers file"
	exit 1
else
	echo
	echo "## Successfully wrote bitfile from '${ARTIFACT}'"
	echo "## Shutdown this machine with 'sudo shutdown -h now', log into 'https://$(hostname)-ilo.aus.optiver.com/start.html', and restart this machine."
	echo "## If 'https://$(hostname)-ilo.aus.optiver.com/start.html' doesn't work, try the link for your machine from https://wiki.site.optiver.com/display/HARDWARE/Hardware+Lab"
	echo "## Username: 'hardware'"
	echo "## Password: 'hardware'"
	echo "## These pages probably need to be opened in Firefox or IE :("
	echo
	echo "## Before you restart, remember to to tell the other users of this box."
	echo "## The following users are currently log into this machine:"
	who
	echo
	sleep 1
	exit 0
fi
