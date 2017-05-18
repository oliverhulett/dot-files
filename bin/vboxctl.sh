#!/bin/bash
##
##	vboxctl
##
##	Control Sun VirtualBox VMs.
##
GLOBAL_INCLUDE="/usr/local/lib/VBox_ctl/"
VRDP_AUTH_PAM_SERVICE=vrdpauth
DEF_VBOX_MACH=
DEF_VBOX_USER=vboxuser
DEF_VBOX_DATA="/home/data/VMs/"
DEF_VBOX_USER_HOME="$DEF_VBOX_DATA/.VirtualBox"

##	Print the usage header.
function header()
{
	echo "$(basename $0) [-u USER] [-h HOME] [-i <include>] [[-v] VM] [--] <CMD> [CMD_OPTIONS]"
	echo
	echo -e "\t-u USER"
	echo -e "\t\tVirtualBox user.  Default USER is $DEF_VBOX_USER"
	echo -e "\t-h HOME"
	echo -e "\t\tVirtualBox home directory.  Default USER_HOME is $DEF_VBOX_USER_HOME"
	echo -e "\t-i <include>"
	echo -e "\t\tInclude a shell file containing functions do_* that define preconfigured commands."
	echo -e "\t-v VM"
	echo -e "\t\tVirtual machine name.  Default VM is ${DEF_VBOX_MACH:-first in list vms}"
}

##	Print usage information and exit.
function usage()
{
	header
	echo -e "\tPreconfigured commands are:"

	for func in ${!USAGE[@]}; do
		echo -ne "\t\t$func\t"
		width=$((${#func} / 8))
		while [ $width -lt 1 ]; do
			echo -ne "\t"
			width=$(($width + 1))
		done
		echo -e "${USAGE[$func]}"
	done

	echo
	echo -e "\tAny other command string and its options will be passed directly to VBoxManage"
}

##	Call the VBoxManage command as the correct user.
function vbox_manage()
{
	echo "VBoxManage $*" 1>&2
	sudo -u "$VBOX_USER" VRDP_AUTH_PAM_SERVICE="$VRDP_AUTH_PAM_SERVICE" VBOX_USER_HOME="$VBOX_USER_HOME" VBoxManage "$@" 2>&1
}

##	Call the VirtualBox command as the correct user.
function vbox_virtualbox()
{
	echo "VirtualBox $*" 1>&2
	(
		XAUTH=$(sudo -u "$VBOX_USER" tempfile -m 0600)
		trap "sudo -u '$VBOX_USER' rm -r -- '$XAUTH'" EXIT
		xauth nlist | sudo -u "$VBOX_USER" XAUTHORITY="$XAUTH" xauth nmerge -
		sudo -u "$VBOX_USER" XAUTHORITY="$XAUTH" VRDP_AUTH_PAM_SERVICE="$VRDP_AUTH_PAM_SERVICE" VBOX_USER_HOME="$VBOX_USER_HOME" VirtualBox "$@" 2>&1
		sudo -u "$VBOX_USER" rm -r -- "$XAUTH"
		trap - EXIT
	)
}

##	Set default arguments.
VBOX_MACH=$DEF_VBOX_MACH
VBOX_USER=$DEF_VBOX_USER
if [ -z "$VBOX_USER_HOME" ]; then
	VBOX_USER_HOME=$DEF_VBOX_USER_HOME
fi

##	Include global includes to prime the USAGE variable.
if [ -d "$GLOBAL_INCLUDE" ]; then
	source "$GLOBAL_INCLUDE"/*
else
	source "$GLOBAL_INCLUDE"
fi

##	Parse arguments.
##	Note that we use `"$@"' to let each command-line parameter expand to a separate word. The
##	quotes around `$@' are essential!  We need TEMP as the `eval set --' would nuke the return
##	value of getopt.
TEMP=`getopt -o i:v:u:? -n $(basename $0) -- "$@"`
if [ $? != 0 ] ; then
	echo "Terminating..." >&2
	usage
	exit 1
fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"
while true; do
	case "$1" in
		-v)
			VBOX_MACH=$2
			shift 2
			;;
		-u)
			VBOX_USER=$2
			shift 2
			;;
		-h)
			VBOX_USER_HOME=$2
			shift 2
			;;
		-i)
			if [ -d "$2" ]; then
				source "$2"/*
			else
				source "$2"
			fi
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			break
			;;
	esac
done

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

#sudo -v

AVAIL_VMS=$(vbox_manage list vms 2>/dev/null | sed -nre 's/^"?([^"]+)"?.+$/\1/p')
if [ -z "$VBOX_MACH" ]; then
	if ! echo $AVAIL_VMS | grep "$1" 2>&1 >/dev/null; then
		VBOX_MACH=$(vbox_manage list vms 2>/dev/null | head -n1 | sed -nre 's/^"?([^"]+)"?.+$/\1/p')
	else
		VBOX_MACH=$1
		shift
	fi
fi

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

CMD=$1
if [ "$2" = "help" -o "$2" = "-h" -o "$2" = "-?" -o "$2" = "h" -o "$2" = "?" ]; then
	if [ "$(type -t "help_$CMD" 2>/dev/null)" = "function" ]; then
		header
		echo
		echo -e "CMD = $CMD\t${USAGE[$CMD]}"
		eval "help_$CMD" | sed -re 's/^/\t/'
	else
		usage
	fi
else
	if [ "$(type -t "do_$CMD" 2>/dev/null)" = "function" ]; then
		shift
		if ! eval "do_$CMD" "$@"; then
			true vbox_manage "$CMD" "$@"
		fi
	else
		vbox_manage "$@"
	fi
fi

exit 0
