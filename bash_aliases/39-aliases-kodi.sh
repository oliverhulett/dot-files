# shellcheck shell=bash
# Kodi stuff.
## Make sure you set kodi in /etc/hosts
## Make sure you install kodicall.sh in your path

alias kodiclean="kodicall VideoLibrary.Clean"
function kodiscan()
{
	if [ $# -eq 0 ]; then
		kodicall "VideoLibrary.Scan"
	else
		kodicall "VideoLibrary.Scan" "directory" '"'"$*"'"'
	fi
}

