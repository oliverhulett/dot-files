#!/bin/bash -e

if [ $# -ne 1 -o "$1" == "-h" -o "$1" == "-?" ]; then
	echo 1>&2 "$(basename -- "$0") requires a bit-file image to flash."
	echo 1>&2 "$(basename -- "$0") <bitfile>"
	exit 1
fi
ARTIFACT="$1"
shift

HW_AU_REPO=( "ssh://git@git.comp.optiver.au:7999/fpga/hardware_au.git" "ssh://git@git:7999/fpga/hardware_au.git" )
HW_AU_DIR="${HOME}/repo/fpga/hardware_au"

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

if [ -d "${HW_AU_DIR}/.git" ]; then
	pushd "${HW_AU_DIR}"
	run git stash
	run git pull --force
	run git stash pop || true
else
	mkdir -p "${HW_AU_DIR}"
	pushd "${HW_AU_DIR}"
	for url in "${HW_AU_REPO[@]}"; do
		run git clone "${url}" . || true
	done
	test -d "${HW_AU_DIR}/.git"
fi

function cleanup()
{
	for (( i=0; i < $LVLS; i=$(( $i + 1 )) )); do
		popd
	done
}
trap cleanup EXIT

DEPLOY_DIR="${HW_AU_DIR}/board_support_packages/deploy"
KO_FILE="${DEPLOY_DIR}/chemnitz.ko"
DRIVER_DIR="${HW_AU_DIR}/board_support_packages/drivers/fiberblaze_smartnic/v7690-1_7_2/driver"
if [ ! -e "${KO_FILE}" ]; then
	( cd "${DRIVER_DIR}" && run make )
	run cp "${DRIVER_DIR}/chemnitz.ko" "${KO_FILE}"
fi

pushd "${DEPLOY_DIR}"
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

echo "## About to flash the board.  If anyone asks, you're tageting board: fex_fb"
#echo "fex_fb" | run sudo "${DEPLOY_DIR}/flash_tool.py" "${BITFILE}"
run sudo "${DEPLOY_DIR}/flash_tool.py" "${BITFILE}"

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
