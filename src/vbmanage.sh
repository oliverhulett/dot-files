##
##	vboxmanage.sh
##
##	Control Sun VirtualBox VMs.  This is an include file to define the commands to control VMs.
##	This is an attempt to make this script a little neater and more modular.
##

# ##	do_
# ##	Does what it sais on the lack of box.
# USAGE['']=""
# function do_()
# {
# }

##	Declare specific functions here.  To add the to the usage output create a simple description in
##	$USAGE[] with the function command as the key.

declare -A USAGE

##	do_gui
##	Show the GUI.
USAGE['gui']="Show the VirtualBox GUI."
function do_gui()
{
	vbox_virtualbox
}

##	do_help
##	Print VBoxManage help.
USAGE['help']="Print VBoxManage help."
function do_help()
{
	vbox_manage --help | less
}

##	do_list
##	List available VMs.
USAGE['list']="List available VMs."
function do_list()
{
	if [ $# -eq 0 ]; then
		vbox_manage list vms
	else
		vbox_manage list "$@"
	fi
}

##	do_status
##	Print the status of the virtual machine.
USAGE['status']="Monkey see, Monkey print State."
function do_status()
{
	vbox_manage showvminfo "$VBOX_MACH" --details | grep State
}

##	do_info
##	Print the status of the virtual machine.
USAGE['info']="Monkey see, Monkey print."
function do_info()
{
	vbox_manage showvminfo "$VBOX_MACH" --details
}

##	do_on
##	Turn the virtual machine on.
USAGE['on']="Live my precious.  Live!"
function help_on()
{
	echo -e "If paused, unpause.  If off, on.  Set clipboard to bidirectional, start headless mode."
}
function do_on()
{
	##	If paused, unpuase.
	if [ "$(type -t "do_status" 2>/dev/null)" = "function" ]; then
		if do_status | grep paused >/dev/null 2>&1; then
			if [ "$(type -t "do_resume" 2>/dev/null)" = "function" ]; then
				do_resume
				return
			fi
		fi
	fi

	vbox_manage modifyvm "$VBOX_MACH" --clipboard bidirectional
	vbox_manage startvm "$VBOX_MACH" --type headless

	if [ $# -ge 2 ]; then
		width=$1
		height=$2
		shift 2
	fi
}

##	do_off
##	Turn the virtual machine off.  Try a proper shutdown, then force a power off.
USAGE['off']="Press the big virtual power button in the sky."
function do_off()
{
	if [ "$(type -t "do_status" 2>/dev/null)" = "function" ]; then
		if do_status | grep paused >/dev/null 2>&1; then
			if [ "$(type -t "do_resume" 2>/dev/null)" = "function" ]; then
				do_resume
			fi
		fi
	fi

	vbox_manage controlvm "$VBOX_MACH" acpipowerbutton

	cnt=120
	while [ $cnt -ge 0 ] && ps -C VBoxHeadless >/dev/null 2>&1; do
		echo -en "$cnt.."
		sleep 10
		cnt=$((cnt - 10))
	done
	echo

	if ps -C VBoxHeadless >/dev/null 2>&1; then
		vbox_manage controlvm "$VBOX_MACH" poweroff
	fi
}

##	do_reboot
##	Reboot a virtual machine.
##	@arg	The port for VRDE sessions.
##	@arg	The screen size hint width.
##	@arg	The screen size hint height.
USAGE['reboot']="Have you tried turning it off and on again?"
function help_reboot()
{
	help_on
}
function do_reboot()
{
	if [ "$(type -t "do_off" 2>/dev/null)" = "function" ]; then
		do_off
	fi
	if [ "$(type -t "do_on" 2>/dev/null)" = "function" ]; then
		do_on "$@"
	fi
}

##	do_pause
##	Pause the virtual machine.
USAGE['pause']="Pause the VM"
function do_pause()
{
	vbox_manage controlvm "$VBOX_MACH" pause
}

##	do_resume
##	Resume the virtual machine.
USAGE['resume']="Resume the VM"
function do_resume()
{
	vbox_manage controlvm "$VBOX_MACH" resume
}

##	do_createvm
##	Create a VM.  Watch me pull a machine out of my hat.  I'm like a god to you people.
##	@arg	Details about the machine, names, places, etc.
USAGE['createvm']="Create a VM."
function help_createvm()
{
	echo "Create a Virtual Machine out of whole cloth."
	echo "createvm <NAME> [--no-register] [ostype] [basedir]"
	vbox_manage createvm
}
function do_createvm()
{
	if [ $# -eq 0 ]; then
		help_createvm
	else
		NAME=$1
		shift
		REGISTER="--register"
		OS_TYPE=
		BASE_DIR=
		while [ $# -ne 0 ]; do
			if [ "$1" = "--no-register" ]; then
				REGISTER=
				shift
			elif [ -z "$BASE_DIR" -a -d "$1" ]; then
				BASE_DIR="$1"
				shift
			elif [ -z "$OS_TYPE" ]; then
				OS_TYPE="$1"
				shift
			elif [ "$1" = "--" ]; then
				shift
				break
			else
				break
			fi
		done
		if [ -z "$OS_TYPE" ]; then
			#	Select OS_TYPE
			TYPES="$(vbox_manage list ostypes | sed -nre 's/^ID: +(.+)$/\1, /p')"
			while [ -z "$OS_TYPE" ]; do
				read -rp "What guest OS did you want to run? [(L)ist]: " OS_TYPE
				if [ "$OS_TYPE" = "L" -o "$OS_TYPE" = "LIST" -o "$OS_TYPE" = "List" \
					-o "$OS_TYPE" = "l" -o "$OS_TYPE" = "list" ]; then
					OS_TYPE=
					echo ${TYPES:0: -2}
				fi
			done
		fi
		while [ -z "$BASE_DIR" -o ! -d "$BASE_DIR" ]; do
			read -rp "Where shall we put the VM? [$DEF_VBOX_DATA]: " BASE_DIR
			if [ -z "$BASE_DIR" ]; then
				BASE_DIR="$DEF_VBOX_DATA"
			fi
		done

		vbox_manage createvm --name "$NAME" $REGISTER --ostype "$OS_TYPE" --basefolder "$BASE_DIR"
		[ $? -eq 0 ] || return $?
		VBOX_MACH=$NAME

		SIZE=
		VMEM=
		if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			SIZE=$1
			shift
		fi
		if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			VMEM=$1
			shift
		fi
		while ! echo $SIZE | grep -E '^[0-9]+$' >/dev/null 2>&1; do
			read -rp "Memory size (in MB): " SIZE VMEM
		done
		if ! echo $VMEM | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			VMEM=128
		fi
		do_modifyvm --memory $SIZE --vram $VMEM

		HDD="$1"
		if [ -e "$HDD" ]; then
			shift
		else
			read -rp "Attach existing hard-drive or leave blank to create new drive: " HDD
		fi
		if [ "$OS_TYPE" = "WindowsXP" ]; then
			if [ -e "$HDD" ]; then
				do_attachhdd "$HDD" "ide"
			else
				do_createhdd $1 "ide"
			fi
		else
			if [ -e "$HDD" ]; then
				do_attachhdd "$HDD" $*
			else
				do_createhdd $*
			fi
		fi

		do_storagectl "IDE Controller" "ide"
		do_dvdctl

		do_modifyvm --ioapic on
		do_modifyvm --boot1 dvd --boot2 disk --boot3 none --boot4 none
		do_modifyvm --nic1 bridged --bridgeadapter1 eth0

		sudo -u vboxuser chmod -R g=u "$BASE_DIR/$VBOX_MACH"
		find "$BASE_DIR/$VBOX_MACH" -type d -print0 | xargs -t0 sudo -u vboxuser setfacl -d -m u::rwx,m:rwx
		find "$BASE_DIR/$VBOX_MACH" -type d -print0 | xargs -t0 sudo -u vboxuser setfacl -d -m g::rx,m:rwx
		find "$BASE_DIR/$VBOX_MACH" -type d -print0 | xargs -t0 sudo -u vboxuser chmod g+rxs,u+rx
		find "$BASE_DIR/$VBOX_MACH" -type f -print0 | xargs -t0 sudo -u vboxuser chmod g+r,u+rw

		do_vrde
	fi
}

##	do_deletevm
##	Delete a VM.  Do not question your god!
##	@arg	The machine to delete.
USAGE['deletevm']="Delete a VM."
function help_deletevm()
{
	echo "Delete a Virtual Machine."
	echo "deletevm <NAME> --no-delete"
	vbox_manage unregistervm
}
function do_deletevm()
{
	NAME=$1
	DELETE="--delete"
	for arg in "$@"; do
		if [ "$arg" = "--no-delete" ]; then
			DELETE=
		fi
	done
	MACHINES="$(vbox_manage list vms 2>/dev/null)"
	while [ -z "$NAME" -o "$NAME" = "--no-delete" ]; do
		read -rp "Which machine do you want to delete? [(L)ist]: " NAME
		if [ "$NAME" = "L" -o "$NAME" = "LIST" -o "$NAME" = "List" \
			-o "$NAME" = "l" -o "$NAME" = "list" ]; then
			NAME=
			echo "$MACHINES"
		fi
	done
	if [ "$(echo $MACHINES | grep -c "$NAME" 2>/dev/null)" -ne 1 ]; then
		echo "'$NAME' is not a registered virtual machine or is not a unique name."
		echo "  Try again with a machine UUID."
	else
		vbox_manage unregistervm "$NAME" $DELETE
	fi
}

##	do_storagectl
##	Create a virtual storage controller.
USAGE["storagectl"]="Create a virtual storage controller."
function help_storagectl()
{
	echo "Create a virtual storage controller."
	echo "storagectl [--remove] NAME [ide|sata|scsi|floppy] [CONTROLLER]"
	vbox_manage storagectl
}
function do_storagectl()
{
	unset TYPE NAME CONTROLLER REMOVE
	REMOVE=
	TYPE=
	NAME=
	CONTROLLER=
	while [ $# -ne 0 ]; do
		arg="$1"
		if [ "$1" = "--remove" -o "$1" = "remove" ]; then
			REMOVE="--remove"
			shift
		fi
		if [ "${1,,*}" = "ide" ]; then
			TYPE="ide"
			shift
		elif [ "${1,,*}" = "sata" ]; then
			TYPE="sata"
			shift
		elif [ "${1,,*}" = "scsi" ]; then
			TYPE="scsi"
			shift
		elif [ "${1,,*}" = "floppy" ]; then
			TYPE="floppy"
			shift
		fi
		if [ -z "$NAME" ]; then
			NAME="$1"
			shift
			continue
		fi
		if [ -z "$TYPE" ]; then
			while [ "$TYPE" != "ide" -a "$TYPE" != "sata" -a "$TYPE" != "scsi" -a "$TYPE" != "floppy" ]; do
				read -rp "Disk type [ide|sata|scsi|floppy]: " TYPE
			done
		fi
		if [ "$arg" = "$1" ]; then
			break
		fi
	done
	if [ $# -ne 0 ]; then
		CONTROLLER="--controller $1"
		shift
	fi

	if [ -n "$REMOVE" ]; then
		vbox_manage storagectl "$VBOX_MACH" --name "$NAME" --remove
	elif ! vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | grep -E '^Storage Controller Name .* '"$NAME"'$' 2>&1 >/dev/null; then
		vbox_manage storagectl "$VBOX_MACH" --name "$NAME" --add $TYPE $CONTROLLER "$@"
	elif [ $# -ne 0 ]; then
		vbox_manage storagectl "$VBOX_MACH" --name "$NAME" $CONTROLLER "$@"
	fi
}

##	do_attachhdd
##	Attach existing storage to an existing VM.
##	@arg	The storage filename.
##	@arg	Storage controller type hint.
USAGE['attachhdd']="Attach existing storage to an existing VM."
function help_attachhdd()
{
	echo "Attach existing storage to an existing VM."
	echo "attachhdd <filename> [type_hint]"
	vbox_manage storageattach
}
function do_attachhdd()
{
	if [ $# -eq 0 ]; then
		help_attachhdd
		return
	fi

	unset TYPE TYPESTR filename dev port
	TYPE=
	TYPESTR=
	dev=
	port=

	filename="$1"
	shift
	if [ ! -e "$filename" ]; then
		echo "Not a valid HDD filename.  $filename"
		return
	fi

	while [ -z "$dev" -o -z "$port" ]; do
		if [ "${1,,*}" = "ide" ]; then
			TYPE="ide"
			shift
		elif [ "${1,,*}" = "sata" ]; then
			TYPE="sata"
			shift
		elif [ "${1,,*}" = "scsi" ]; then
			TYPE="scsi"
			shift
		elif [ -z "$TYPESTR" ]; then
			TYPESTR="$1"
			shift
		fi

		if [ -z "$dev" -o -z "$port" ]; then
			while [ "$TYPE" != "ide" -a "$TYPE" != "sata" -a "$TYPE" != "scsi" ]; do
				read -rp "Disk type [ide|sata|scsi]: " TYPE
			done
			if [ -z "$TYPESTR" ]; then
				if [ "$TYPE" = "ide" ]; then
					TYPESTR="IDE Controller"
				elif [ "$TYPE" = "sata" ]; then
					TYPESTR="SATA Controller"
				elif [ "$TYPE" = "scsi" ]; then
					TYPESTR="SCSI Controller"
				fi
			fi
			do_storagectl "$TYPESTR" $TYPE
		fi

		eval $(vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | sed -nre 's/^'"$TYPESTR"'.+\(([0-9]+), ([0-9]+)\): ([^\(]+)( \(.+)?$/\1 \2 \3/p' | tail -n1 | {
			read p d cd
			echo 'port="'$p'"; dev="'$d'";'
			}
		)
		if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			port=$1
			shift
		fi
		if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			dev=$1
			shift
		fi
		if [ -n "$dev" ]; then
			dev=$((dev + 1))
		else
			dev=0
		fi
		if [ -z "$port" ]; then
			port=0
		fi
	done

	vbox_manage storageattach $VBOX_MACH --storagectl "$TYPESTR" --port $port --device $dev --type hdd --medium "$filename"
}

##	do_createhdd
##	Create a virtual hard drive.
USAGE['createhdd']="Create a virtual hard drive."
function help_createhdd()
{
	echo "Create a virtual hard drive"
	echo "createhdd [SIZE] [TYPE | CONTROLLER]"
	vbox_manage createhd
}
function do_createhdd()
{
	unset SIZE filename
	SIZE=
	if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
		SIZE=$1
		shift
	fi
	while ! echo $SIZE | grep -E '^[0-9]+$' >/dev/null 2>&1; do
		read -rp "Disk size (in MB): " SIZE
	done

	cnt=0
	BASE_DIR="$1"
	if [ -z "$BASE_DIR" -o ! -d "$BASE_DIR" ]; then
		BASE_DIR="$DEF_VBOX_DATA"
	else
		shift
	fi
	filename="$BASE_DIR/$VBOX_MACH/$VBOX_MACH-`printf '%03d' $cnt`.vdi"
	while [ -e "$filename" ]; do
		cnt=$((cnt + 1))
		filename="$BASE_DIR/$VBOX_MACH/$VBOX_MACH-`printf '%03d' $cnt`.vdi"
	done
	vbox_manage createhd --filename "$filename" --size $SIZE

	do_attachhdd "$filename" "$@"
}

##	do_modifyvm
##	Modify a VM.  Usually things you can't do whilst running.
##	@arg	The modification to make.
USAGE['modifyvm']="Modify a VM.  Like controlvm only when it's stopped."
function help_modifyvm()
{
	echo "Modify a VM.  Like controlvm only when it's stopped."
	vbox_manage modifyvm
}
function do_modifyvm()
{
	if [ $# -eq 0 ]; then
		help_modifyvm
	else
		vbox_manage modifyvm "$VBOX_MACH" "$@"
	fi
}

##	do_controlvm
##	Control a VM.  Usually things you can do whilst running.
##	@arg	The control to use.  It's super effective.
USAGE['controlvm']="Control a VM.  Like modifyvm only whilst it's running."
function help_controlvm()
{
	echo "Control a VM.  Like modifyvm only whilst it's running."
	vbox_manage controlvm
}
function do_controlvm()
{
	if [ $# -eq 0 ]; then
		help_controlvm
	else
		vbox_manage controlvm "$VBOX_MACH" "$@"
	fi
}

##	do_guestcontrol
##	Control a guest.  Muhahaha!
##	@arg	exec[ute]|copyfrom|copyto|cp|createdir[ectory]|mkdir|md|stat|updateadditions
##	@arg	Usually a filename.
USAGE['guestcontrol']="Control a guest.  Muhahaha!"
function help_guestcontrol()
{
	echo -e "Control?  This is S.P.E.C.T.O.R.  All your base are belong to us!"
	echo -e "\texec[ute] | copyfrom | copyto|cp | createdir[ectory]|mkdir|md | stat | updateadditions"
	echo -e "\t[<files/dirs>]  Usually a file name or a directory, sometimes nothing."
	echo -e "\t                Other stuff depending on what you put places."
}
function do_guestcontrol()
{
	unset action username user password pass domain
	if [ $# -eq 0 ]; then
		help_guestcontrol
		vbox_manage guestcontrol
	elif [ "$1" = "updateadditions" ]; then
		vbox_manage guestcontrol "$VBOX_MACH" "$@"
	else
		action="$1"
		shift
		declare -a args
		username="--username"
		user=
		password="--password"
		pass=
		for arg in "$@"; do
			if [ "$arg" = "--username" ]; then
				username=
			elif [ -z "$username" -a -z "$user" ]; then
				user="$arg"
			elif [ "$arg" = "--password" ]; then
				password=
			elif [ -z "$password" -a -z "$pass" ]; then
				user="$arg"
			else
				args[${#args[@]}]="$arg"
			fi
		done
		if [ "$username" = "--username" ]; then
			domain="$(hostname -y)"
			if [ -z "$domain" ]; then
				domain="$VBOX_MACH"
			fi
			user="$domain\\$(whoami)"
			read -rp "Username [$user]: " user
			if [ -z "$user" ]; then
				user="$domain\\$(whoami)"
			fi
			username="--username '$user'"
		fi
		if [ "$password" = "--password" ]; then
			read -rsp "Password for $user: " pass
			password="--password '$pass'"
			echo
		fi
		echo "VBoxManage guestcontrol $VBOX_MACH $action --username $user --password ******** ${args[*]}"
		vbox_manage guestcontrol "$VBOX_MACH" $action $username $password "${args[@]}" 2>/dev/null
	fi
}
function help_guestctl()
{
	help_guestcontrol "$@"
}
function do_guestctl()
{
	do_guestcontrol "$@"
}

##	do_dvdctl
##	Map a disc to the DVD drive.
##	@arg	The disc drive to map.  Defaults to host:/dev/sr0.
##	@arg	The device number
##	@arg	The port number.
USAGE['dvdctl']="Map a disc to the DVD drive.  Defaults to host:/dev/sr0."
function help_dvdctl()
{
	echo -e "Attach DVD drive."
	echo -e "\t[disc]  The device or file to connect.  Defaults to host:/dev/sr0."
	echo -e "\t[dev]   The device number on the guest."
	echo -e "\t[port]  The device port number on the guest."
}
function do_dvdctl()
{
	unset disc dev port curdisc
	if [ $# -eq 1 -o $# -eq 3 ]; then
		if [ -n "$1" ]; then
			disc="$1"
		fi
		shift
	fi
	if [ $# -eq 2 ]; then
		if [ -n "$1" ]; then
			dev="$1"
		fi
		if [ -n "$2" ]; then
			port="$2"
		fi
	fi
	if [ -z "$dev" -o -z "$port" ]; then
		eval $(vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | sed -nre 's/^IDE Controller.+\(([0-9]+), ([0-9]+)\): ([^\(]+)( \(.+)?$/\1 \2 \3/p' | {
			maxdev=-1
			while read p d cd; do
				maxdev=$d
				port=$p
				if [ "$cd" = "Empty" ]; then
					port=$p
					dev=$d
					curdisc=$cd
					break
				elif [ "$cd" != "${cd%.iso}" ]; then
					port=$p
					dev=$d
					curdisc=$cd
					break
				elif [ "${cd%%[0-9]}" = "/dev/sr" ]; then
					port=$p
					dev=$d
					curdisc=$cd
					break
				fi
			done; echo 'maxdev="'$maxdev'"; dev="'$dev'"; port="'$port'"; curdisc="'$curdisc'";'
			}
		)
	fi
	if [ -z "$disc" ]; then
		if [ "$curdisc" = "Empty" ]; then
			disc="host:/dev/sr0"
		else
			disc="emptydrive"
		fi
	fi
	if [ -z "$dev" ]; then
		dev=$((maxdev + 1))
	fi
	if [ -z "$port" ]; then
		port=0
	fi

	vbox_manage storageattach "$VBOX_MACH" --storagectl "IDE Controller" --device "$dev" --port "$port" --type dvddrive --medium "$disc"
}

##	do_usbctl
##	Map a USB device to the VM.
USAGE['usbctl']="Select and map a USB device."
function help_usbctl()
{
	echo -e "Connect or disconnect a USB device to an active guest.  The device is identified by UUID."
	echo -e "Just sit back and relax, it'll ask you what to do."
}
function do_usbctl()
{
	unset UUID ATTACH
	vbox_manage list -l usbhost

	read -p "Select Device: " UUID
	if [ -z "$UUID" ]; then
		return
	fi

	read -n1 -p "[A]ttach or [D]etach? " ATTACH
	echo

	if [ "$ATTACH" = "A" -o "$ATTACH" = "a" ]; then
		vbox_manage controlvm "$VBOX_MACH" usbattach "$UUID"
	elif [ "$ATTACH" = "D" -o "$ATTACH" = "d" ]; then
		vbox_manage controlvm "$VBOX_MACH" usbdetach "$UUID"
	fi
}

##	do_uart
##	Configure a UART/serial port.
##	@arg	The UART number to configure.
##	@arg	The arguments for uartmode.
USAGE['uart']="Configure a UART/serial port."
function help_uart()
{
	echo -e "Attach a serial port."
	echo -e "\tnum   The UART number to configure."
	echo -e "\tmode  disconnected | server <pipe> | client <pipe> | file <file> | <devicename>"
}
function do_uart()
{
	unset port iodata dev
	port=1
	if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
		port=$1
		shift
	fi
	iodata=off
	if [ "$1" != "off" ]; then
		case $port in
			1) iodata="0x3F8 4" ;;
			2) iodata="0x2F8 3" ;;
			3) iodata="0x3E8 4" ;;
			4) iodata="0x2E8 3" ;;
		esac
	else
		shift
	fi

	if [ "$iodata" != "off" ]; then
		curdev=$(vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | sed -nre 's/^UART '$port': +(disabled)|UART '$port': +I\/O base: [^,]+, IRQ: [^,]+, (disconnected)|UART '$port': +I\/O base: [^,]+, IRQ: [^,]+, [^'"'"']+'"'"'([^'"'"']+)'"'"'$/\1\2\3/p')
	fi
	if [ $# -eq 0 ]; then
		if [ "$curdev" = "disconnected" ]; then
			dev="/dev/ttyS0"
		elif [ "$curdev" = "disabled" ]; then
			dev="/dev/ttyS0"
		else
			dev="disconnected"
		fi
	fi

	if [ $# -ne 0 ]; then
		vbox_manage modifyvm "$VBOX_MACH" --uartmode$port "$@"
	else
		vbox_manage modifyvm "$VBOX_MACH" --uartmode$port "$dev"
	fi
	vbox_manage modifyvm "$VBOX_MACH" --uart$port $iodata
}

##	do_sharedfolder
##	Share or unshare a host folder to a guest VM.
##	@arg	add|remove a shared folder.
##	@arg	The name of the folder to add or remove."
##	@arg	The host path of the folder to share."
USAGE['sharedfolder']="Share or unshare a host folder to a guest VM."
function help_sharedfolder()
{
	echo -e "Share or unshare a host folder."
	echo -e "\tadd|remove   Adding or removing."
	echo -e "\tname         The name of the folder to add or remove."
	echo -e "\t[path]       The host path of the folder to share."
	echo -e "\t[transient]  Only for one session?."
	echo -e "\t[readonly]   Share the folder readonly."
	echo -e "\t[automount]  Mount the host path automatically when connecting to the shared folder."
}
function do_sharedfolder()
{
	unset action name
	action=
	if [ "$1" = "add" ]; then
		action="add"
		shift
	elif [ "$1" = "remove" ]; then
		action="remove"
		shift
	fi
	if [ $# -eq 0 ]; then
		help_sharedfolder
	fi
	name="$1"
	shift
	if [ -z "$action" ]; then
		if do_info | grep -E "^Name: '$name', Host path:" >/dev/null 2>&1; then
			action=remove
		else
			action=add
		fi
	fi
	if [ "$action" = "add" ]; then
		vbox_manage sharedfolder add "$VBOX_MACH" --name "$name" --hostpath "$@"
	else
		vbox_manage sharedfolder remove "$VBOX_MACH" --name "$name" "$@"
	fi
}
function help_share()
{
	help_sharedfolder "$@"
}
function do_share()
{
	do_sharedfolder "$@"
}

##	do_vrde
##	Set the VRDE properties for headless mode.
##	@arg	The port to use for VRDE connections.
##	@arg	Multiconnection mode or reuse connection mode.
##	@arg	Authentication mode.
USAGE['vrde']="Set the VRDE properties for headless mode."
function help_vrde()
{
	echo -e "\t[port]         The VRDE port to listen on, or we'll try to select one intelligently."
	echo -e "\t[multi|reuse]  The connection mode."
	echo -e "\t[auth]         The authentication method."
}
function do_vrde()
{
	unset port authtype
	##	VRDE Port:  Can be the first argument or we'll try to select one intelligently (sort of.)
	if [ $# -ge 1 ]; then
		if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
			port=$1
			shift
		fi
	fi
	if [ -z "$port" ]; then
		REGEX='s/^VRDE property: TCP\/Ports += "([0-9]+)".*$/\1/p'
		port=$(vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | sed -nre "$REGEX")
		if [ -z "$port" ]; then
			port=3389
		fi
		for mach in $AVAIL_VMS; do
			if [ "$VBOX_MACH" = "$mach" ]; then
				break;
			fi
			p=$(vbox_manage showvminfo "$mach" 2>/dev/null | sed -nre "$REGEX")
			if [ "$p" = "$port" ]; then
				port=$(($port + 1))
			fi
		done
	fi

	if [ -n "$port" ]; then
		vbox_manage modifyvm "$VBOX_MACH" --vrdeport $port
	fi

	authtype="external"
	if [ $# -ge 1 ]; then
		case $1 in
			'n'|'null')
				authtype="null"
				shift
				;;
			'e'|'external')
				authtype="external"
				shift
				;;
			'g'|'guest')
				authtype="guest"
				shift
				;;
		esac
	fi
	vbox_manage modifyvm "$VBOX_MACH" --vrdeauthtype "$authtype"

	vbox_manage modifyvm "$VBOX_MACH" --vrdemulticon on
	vbox_manage modifyvm "$VBOX_MACH" --vrdereusecon on

	vbox_manage modifyvm "$VBOX_MACH" --vrdeaddress 0.0.0.0
	vbox_manage modifyvm "$VBOX_MACH" --vrde on
}

##	do_screensize
##	Set the video mode screen size hint for a headless VM.
##	@arg	The screen size hint width.
##	@arg	The screen size hint height.
##	@arg	The screen size hint depth.
USAGE['screensize']="Set the video mode screen size hint for a headless VM."
function help_screensize()
{
	echo -e "\t[width]   The screen size hint for the width."
	echo -e "\t[height]  The screen size hint for the height."
	echo -e "\t[depth]   The screen size hint for the depth."
	echo -e "OR"
	echo -e "\tbigger    Increase the screen size hint."
	echo -e "OR"
	echo -e "\tsmaller   Decrease the screen size hint."
	echo -e "OR"
	echo -e "\tindex     Set the screen size hint."
	echo -e "Pre-selectable screen size hints are:"
	echo -e "\t800x600  1024x768  1152x580  1152x864  1280x960  1280x1024  1600x1200  1834x934"
}
function do_screensize()
{
	unset width height depth
	if [ $# -gt 1 ]; then
		if [ -n "$1" ]; then
			width="$1"
			shift
		fi
		if [ -n "$1" ]; then
			height="$1"
			shift
		fi
		if [ -n "$1" ]; then
			depth="$1"
			shift
		fi
	fi
	WIDTHS=( 800 1024 1152 1152 1280 1280 1600 1834)
	HEIGHTS=(600  768  580  864  960 1024 1200  934)
	if echo $1 | grep -E '^[0-9]+$' >/dev/null 2>&1; then
		if [ $1 -lt ${#WIDTHS[@]} ]; then
			width=${WIDTHS[$1]}
			height=${HEIGHTS[$1]}
			shift
		fi
	fi
	if [ $# -ne 0 ]; then
		eval $(vbox_manage showvminfo "$VBOX_MACH" 2>/dev/null | sed -nre 's/^Video mode:[^0-9]+([0-9]+)x([0-9]+)x([0-9]+)$/width=\1; height=\2; depth=\3;/p')
		if [ "$1" = "bigger" ]; then
			for i in "${!WIDTHS[@]}"; do
				if [ $width -lt ${WIDTHS[$i]} ]; then
					width=${WIDTHS[$i]}
					height=${HEIGHTS[$i]}
					break
				fi
			done
		elif [ $1 = "smaller" ]; then
			for i in ${!WIDTHS[@]}; do
				idx=$((${#WIDTHS[@]} - $i - 1))
				if [ $width -gt ${WIDTHS[$idx]} ]; then
					width=${WIDTHS[$idx]}
					height=${HEIGHTS[$idx]}
					break
				fi
			done
		elif [ $1 = "big" ]; then
			width=1834
			height=934
		elif [ $1 = "small" ]; then
			width=1152
			height=580
		fi
	fi

	if [ -z "$width" ]; then
		width=1152
	fi
	if [ -z "$height" ]; then
		height=580
	fi
	if [ -z "$depth" ]; then
		depth=32
	fi

	vbox_manage controlvm "$VBOX_MACH" setvideomodehint $width $height $depth
}
function help_ss()
{
	help_screensize "$@"
}
function do_ss()
{
	do_screensize "$@"
}
