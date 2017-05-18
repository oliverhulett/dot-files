#!/bin/bash
##
##	Dionysus
##
VBOX_USER=vboxuser

#xauth nlist | gksudo -d --user "$VBOX_USER" '/bin/bash -xc (
#	VRDP_AUTH_PAM_SERVICE=vrdpauth
#	VBOX_DATA="/home/data/VMs/"
#	VBOX_USER_HOME="$VBOX_DATA/.VirtualBox"
#	XAUTH=`tempfile -m 0600`
#	trap "rm -r -- $XAUTH" EXIT
#	XAUTHORITY="$XAUTH" xauth nmerge -
#	XAUTHORITY="$XAUTH" VRDP_AUTH_PAM_SERVICE="$VRDP_AUTH_PAM_SERVICE" VBOX_USER_HOME="$VBOX_USER_HOME" VBoxManage startvm "Dionysus" 2>&1
#	rm -r -- "$XAUTH"
#	trap - EXIT
#)'
VRDP_AUTH_PAM_SERVICE=vrdpauth VBOX_DATA="/home/data/VMs/" VBOX_USER_HOME="$VBOX_DATA/.VirtualBox" VRDP_AUTH_PAM_SERVICE="$VRDP_AUTH_PAM_SERVICE" VBOX_USER_HOME="$VBOX_USER_HOME" VBoxManage startvm "Dionysus" --type sdl
