# shellcheck shell=bash
# Aliases
source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh"

alias lssc='lss --color=none'
alias lsc='lss --color=none'
alias lslc='lsl --color=none'
alias lsnc='lsn --color=none'
alias lsnl='lsn -l'
alias lsln='lsn -l'
alias lsnlc='lsnc -l'
alias lsncl='lsnc -l'
function lss
{
	# List all with indicators, human readable sizes and no backups
	command ls -ABhF --color=always "$@"
}
function lsn
{
	# No -A, No -B (-B implies -a)
	command ls -hF --color=always "$@"
}
function lsl
{
	# With -l, No -B
	command ls -AlhF --color=always "$@"
}
alias ls='lss '

function per_os_alias()
{
	set -x
	OPTS=$(getopt -o "w:d:m:l:" --long "windows:,windoze:,mac:,darwin:,linux:" -n "per_os_alias" -- "$@")
	es=$?
	if [ $es != 0 ]; then
		echo 'per_os [-wmdl] [--windoze=] [--windows] [--mac=] [--darwin=] [--linux=] <default>'
		return $es
	fi
	eval set -- "${OPTS}"
	local ALIAS=
	while true; do
		case "$1" in
			-w | --windows | --windoze )
				if [ "$(uname -s)" == 'MINGW' ]; then
					ALIAS="$2"
				fi
				shift 2
				;;
			-d | -m | --mac | --darwin )
				if [ "$(uname -s)" == 'Darwin' ]; then
					ALIAS="$2"
				fi
				shift 2
				;;
			-l | --linux )
				if [ "$(uname -s)" == 'Linux' ]; then
					ALIAS="$2"
				fi
				shift 2
				;;
			'--' )
				shift
				break
				;;
			* )
				break
				;;
		esac
	done
	if [ -n "${ALIAS}" ]; then
		alias "$1"="${ALIAS}"
	else
		alias "$1"="$2"
	fi
	set +x
}

per_os_alias cp -w "cp --preserve" "cp --preserve=all"
alias sudo='sudo -E'
alias mount='mount -l'
alias sdiff='sdiff --strip-trailing-cr -bB'
alias diff='diff -wB'
per_os_alias time -m "/usr/local/bin/time" "/usr/bin/time"
alias chmod='chmod -c'
alias eject='eject -T'
alias file='file -krz'
per_os_alias top -m "top -o cpu" "top -c"
export LESS='-RFXiMx4'
alias less="less ${LESS}"

per_os_alias ifconfig -w "ipconfig" "sudo /sbin/ifconfig"

GREP_ARGS=
GREP_ARGS_NC=
case "$(uname -s)" in
	'*MINGW*' )
		# MINGW's version of grep doesn't support --exclude or --color.
		# There may be a better test, version for example.
		GREP_ARGS=
		GREP_ARGS_NC=
		;;
	'*' )
		GREP_ARGS="--exclude='.svn' --exclude='.git' --color=always"
		GREP_ARGS_NC="--exclude='.svn' --exclude='.git' --color=never"
		;;
esac
alias grep="command grep ${GREP_ARGS} -nT"
alias ngrep="command grep ${GREP_ARGS_NC}"

alias rsync-a='rsync -zvvpPAXrogthlm'
alias sursync-a='sudo rsync -zvvpPAXrogthlm'
alias rsync-ca='rsync -zvvpPAXrogthlcm'
alias sursync-ca='sudo rsync -zvvpPAXrogthlcm'

alias iotop='sudo iotop'
alias nethogs='sudo nethogs'

alias umount='sudo umount'

alias fuser='sudo fuser -vau'

alias service='sudo service'

alias poweroff='sudo shutdown -hP'
alias powerdown='sudo shutdown -hP'
#alias restart='sudo shutdown -r'
alias reboot='sudo shutdown -r'

# Functions
# #########

unalias cat 2>/dev/null
function cat
{
	FIRST="yes"
	for f in "$@"; do
		if [ "$FIRST" = "no" ]; then
			echo >&2
			echo >&2
		fi
		FIRST="no"
		echo " >>> '$f' <<<" >&2
		echo >&2
		command cat "$f"
	done
}

unalias joinby 2>/dev/null
function joinby()
{
	d="$1"
	if [ ${#1} -eq 1 ]; then
		shift
	else
		d=","
	fi
	echo -n "$1"
	shift
	printf "%s" "${@/#/$d}"
}

unalias _find_alias_or_fn 2>/dev/null
function _find_alias_or_fn()
{
	(
		command grep -lR -E "^[^#]*\balias[[:space:]]+${arg}=" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
		command grep -lR -E "^[^#]*\bfunction[[:space:]]+${arg}[[:space:]]*(\\(\\))?" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
		command grep -lR -E "^[^#]*(\bfunction)?[[:space:]]+${arg}[[:space:]]*\\(\\)" ~/.bashrc ~/.bash_profile ~/.bash_aliases ~/dot-files/bash_common.sh
	) | sort -u
}

unalias which 2>/dev/null
function which()
{
	for arg in "$@"; do
		if [ "${arg:0:1}" = "-" ]; then
			continue
		fi
		for suffix in "" ".sh" ".py"; do
			if type "${arg}${suffix}" 2>/dev/null; then
				arg="${arg}${suffix}"
				break
			fi
		done
		cmd="$arg"
		case `type -t "$arg" 2>/dev/null` in
			alias)
				alias "$arg"
				_find_alias_or_fn "$arg"
				cmd="$(alias "$arg" | sed -re "s/^[^=]+=(.+)$/\1/;s/^["'"'"']//;s/["'"'"']$//;s/command //g;s/builtin //g;s/sudo //g;s/ +-[^ ]+//g") $cmd"
				;;
			keyword)
				;;
			function)
				_find_alias_or_fn "$arg"
				;;
			builtin)
				;;
			*)
				;;
		esac
		echo
		commands=$(command which -a $(echo $cmd | tr ' ' '\n' | sort -u) 2>/dev/null)
		for bin in $commands; do
			while [ -n "$bin" ]; do
				if [ -e "$bin" ]; then
					ls -hl "$bin"
					file "$bin"
				fi
				newbin=$(readlink -n "$bin")
				if [ -z "$newbin" ]; then
					break
				fi
				if [ "${newbin:0:1}" != "/" ]; then
					newbin="$(dirname "$bin")/$newbin"
				fi
				bin="$newbin"
			done
			echo
		done
		if [ -z "$commands" ]; then
			command which "$@"
#			command_not_found_handle "$arg" 2>/dev/null
		fi
#		echo
	done
}
