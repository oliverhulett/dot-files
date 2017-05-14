# Stuff for Loki.
alias rtorrent-dtach="dtach -a /var/lib/rtorrent/fifo -e '^Q'"

function findvids()
{
#	declare -a PATS
#	for arg in "$@"; do
#		if [ ${#PATS[@]} != 0 ]; then
#			PATS[${#PATS[@]}]="-or"
#		fi
#		PATS[${#PATS[@]}]="-iname"
#		PATS[${#PATS[@]}]="*$arg*"
#	done
#
#	echo "Looking for ${PATS[@]}"
	echo "Looking for '$*'"
	find /media/*/ -iname "*${*}*" 2>/dev/null | sort -u -t/ -k5
}

function findvidstime()
{
#	declare -a PATS
#	for arg in "$@"; do
#		if [ ${#PATS[@]} != 0 ]; then
#			PATS[${#PATS[@]}]="-or"
#		fi
#		PATS[${#PATS[@]}]="-iname"
#		PATS[${#PATS[@]}]="*$arg*"
#	done
#
#	echo "Looking for ${PATS[@]}"
	echo "Looking for '$*'"
	find /media/*/ -print0 2>/dev/null | xargs -0 stat --format '%Y :%y %n' | sort -n | cut -d: -f2- | grep --color=never "$*"
}

