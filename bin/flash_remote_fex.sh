#!/bin/bash

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash_common.sh" 2>/dev/null && eval "${capture_output}" || true

if [ $# -ne 2 -o "$1" == "-h" -o "$1" == "-?" ]; then
	echo 1>&2 "$(basename -- "$0") requires a bit-file image to flash and a remote server on which to flash it."
	echo 1>&2 "$(basename -- "$0") <bitfile> <server>"
	exit 1
fi
ARTIFACT="$1"
shift
SERVER="$1"
shift

HW_AU_DIR="${HOME}/repo/fpga/hardware_au"
FLASH_FEX_SCRIPT="${HERE}/flash_fex.sh"
if [ ! -x "${FLASH_FEX_SCRIPT}" ]; then
	echo 1>&2 "Could not find flash_fex.sh as an executable sibling to this file, terminating..."
	exit 1
fi

function run()
{
	for cmd in 'echo $ ' ""; do
		$cmd "$@"
	done
}
echo "Testing SSH key on ${SERVER}";
if ! ssh "${SERVER}" -o ConnectTimeout=2 -o PasswordAuthentication=no echo "SSH key already installed on ${SERVER}"; then
	ssh-copy-id -i "${HOME}/.ssh/id_rsa.pub" "${SERVER}"
	if [ $? -ne 0 ]; then
		read -n1 -s -p "Failed to install your public key from ${HOME}/.ssh/id_rsa.pub.  You're definately going to want this to save you typing in your password over 9000 times.  Press any key to continue or CTRL+C to quit."
		echo
	fi
fi

if [ "${ARTIFACT#http}" == "${ARTIFACT}" ]; then
	BITFILE="$(basename -- "${ARTIFACT}")"
	run scp "${ARTIFACT}" "${SERVER}:${BITFILE}"
else
	BITFILE="${ARTIFACT}"
fi

function cleanup()
{
	run ssh "${SERVER}" "rm $(basename -- "${FLASH_FEX_SCRIPT}") ${BITFILE} 2>/dev/null" || true
}
trap cleanup EXIT

run scp "${FLASH_FEX_SCRIPT}" "${SERVER}:$(basename -- "${FLASH_FEX_SCRIPT}")"
run ssh -t "${SERVER}" "./$(basename -- "${FLASH_FEX_SCRIPT}") ${BITFILE}"
if [ $? -ne 0 ]; then
	echo "## Failed to flash HW on ${SERVER}"
	exit 1
fi

echo
read -n1 -s -p "Shut down ${SERVER}? [Y/n] "
echo
if [ "${REPLY}" == "n" -o "${REPLY}" == "N" ]; then
	exit 0
fi
WHEN="now"
if [ "$(who | cut -d' ' -f1 | grep -v `whoami` | wc -l)" -gt 0 ]; then
	WHEN="+1"
fi
run ssh -t "${SERVER}" "sudo /sbin/shutdown -h $WHEN 'Shutting down to re-flash the FPGA.  You have 1 minute to cancel (sudo /sbin/shutdown -c)'"

echo
read -n1 -s -p "Do the lights out thing, then press any key to continue..."
echo

while ! ssh -o ConnectTimeout=2 -o PasswordAuthentication=no "${SERVER}" 'echo `hostname` back up'; do
	echo "## Waiting for ${SERVER} to come back up"
done

## HACK ATTACK:  repo/fpga/hardware_au is the location in which the FLASH_FEX_SCRIPT checks out the hardware_au project containing the load_driver.sh script.
#run ssh -t "${SERVER}" "sudo rmmod chemnitz; cd repo/fpga/hardware_au/board_support_packages/deploy && sudo ./load_driver.sh; sudo ifup feth0"
## No longer needed...

echo
echo "DONE"
echo
