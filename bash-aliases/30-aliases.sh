# shellcheck shell=bash
# Aliases
# shellcheck disable=SC1090
# shellcheck disable=SC2139 - This expands when defined, not when used. Consider escaping.
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bash-common.sh"

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
alias ls='lss'

function per_os()
{
	OPTS=$(getopt -o "w:d:m:l:" --long "windows:,windoze:,mac:,darwin:,linux:" -n "per_os" -- "$@")
	es=$?
	if [ $es != 0 ]; then
		echo >&2 'per_os [-wmdl] [--windoze=] [--windows] [--mac=] [--darwin=] [--linux=] <default>'
		return $es
	fi
	eval set -- "${OPTS}"
	while true; do
		case "$1" in
			-w | --windows | --windoze )
				if [ "$(uname -s)" == 'MINGW' ]; then
					echo "$2"
					return
				fi
				shift 2
				;;
			-d | -m | --mac | --darwin )
				if [ "$(uname -s)" == 'Darwin' ]; then
					echo "$2"
					return
				fi
				shift 2
				;;
			-l | --linux )
				if [ "$(uname -s)" == 'Linux' ]; then
					echo "$2"
					return
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
	echo "$1"
}

alias chmod='chmod -c'
alias cp="$(per_os -w "cp --preserve" "cp --preserve=all")"
alias diff='diff -wB'
alias eclimd="$(per_os -m "/Applications/Eclipse.app/Contents/Eclipse/eclimd" "eclimd") --background"
alias eject='eject -T'
alias file='file -krz'
alias formatter='bash <(curl -sS https://bitbucket.org/oliverhulett/formatter/raw/master/run.sh)'
alias fuser='sudo fuser -vau'
alias ifconfig="$(per_os -w "ipconfig" "sudo /sbin/ifconfig")"
alias iotop='sudo iotop'
alias mount="$(per_os -l "mount -l" "mount")"
alias nethogs='sudo nethogs'
alias netstat="$(per_os -m "netstat -an -ptcp" "netstat -lnp")"
alias pgrep='pgrep -fl'
alias port='sudo port'
alias pretty='bash <(curl -sS https://bitbucket.org/oliverhulett/formatter/raw/master/run.sh)'
alias rsync='rsync -zvvpPAXrogthlm'
alias sdiff='sdiff --strip-trailing-cr -bB'
alias sudo='sudo -E'
alias time="$(per_os -m "/usr/local/bin/time" "/usr/bin/time")"
alias top="$(per_os -m "top -o cpu" "top -c")"

export LESS='-NRFXiMx4'
alias less="less ${LESS}"
LESSOPEN="|$(per_os -m "/usr/local/bin/lesspipe.sh" "/usr/bin/lesspipe") %s"
export LESSOPEN

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

unalias _find_alias_or_fn 2>/dev/null
function _find_alias_or_fn()
{
	(
		command grep -lR -E "^[^#]*\\balias[[:space:]]+${arg}=" ~/.bashrc ~/.bash_profile ~/.bash-aliases ~/dot-files/bash-common.sh
		command grep -lR -E "^[^#]*\\bfunction[[:space:]]+${arg}[[:space:]]*(\\(\\))?" ~/.bashrc ~/.bash_profile ~/.bash-aliases ~/dot-files/bash-common.sh
		command grep -lR -E "^[^#]*(\\bfunction)?[[:space:]]+${arg}[[:space:]]*\\(\\)" ~/.bashrc ~/.bash_profile ~/.bash-aliases ~/dot-files/bash-common.sh
	) | sort -u
}

function where()
{
	for arg in "$@"; do
		if [ "${arg:0:1}" = "-" ]; then
			continue
		fi
		for suffix in "" ".sh" ".py" ".bash" ".js" ".tsx" ".ts"; do
			if type "${arg}${suffix}" 2>/dev/null >/dev/null; then
				arg="${arg}${suffix}"
				break
			fi
		done
		cmd="$arg"
		case $(type -t "$arg" 2>/dev/null) in
			alias)
				_find_alias_or_fn "$arg"
				;;
			keyword)
				;;
			function)
				_find_alias_or_fn "$arg"
				;;
			builtin)
				;;
			*)
				# shellcheck disable=SC2086,SC2046 - Double quote to prevent globbing and word splitting.
				command which -a $(echo $cmd | tr ' ' '\n' | sort -u) 2>/dev/null
				;;
		esac
	done
}

unalias which 2>/dev/null
function which()
{
	for arg in "$@"; do
		_found_something="false"
		if [ "${arg:0:1}" = "-" ]; then
			continue
		fi
		for suffix in "" ".sh" ".py" ".bash" ".js" ".tsx" ".ts"; do
			if type "${arg}${suffix}" 2>/dev/null; then
				arg="${arg}${suffix}"
				break
			fi
		done
		cmd="$arg"
		where "$arg"
		echo
		# shellcheck disable=SC2086,SC2046 - Double quote to prevent globbing and word splitting.
		commands="$(command which -a $(echo $cmd | tr ' ' '\n' | sort -u) 2>/dev/null)"
		for bin in $commands; do
			while [ -n "$bin" ]; do
				if [ -e "$bin" ]; then
					ls -hl "$bin"
					file "$bin"
					_found_something="true"
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
			if [ -n "$bin" ]; then
				v="$("$bin" --version 2>&1)"
				rv=$?
				echo
				if [ $rv -eq 0 ]; then
					echo "$v"
				else
					echo "$(basename -- "$bin") --version failed"
				fi
			fi
			echo
		done
		if [ "$_found_something" == "false" ]; then
			command which "$arg" 2>/dev/null || command_not_found_handle "$arg"
		fi
		echo
	done
}

function complete() {
	dashp="no"
	if grep -qE '(^| )-[[:alnum:]]*p[[:alnum:]]*( |$)' <(echo "$*"); then
		dashp="yes"
	fi
	if ! grep -qE '(^| )--?[^ ]' <(echo "$*"); then
		read -rsn1 -t5 -p "You issued 'complete' without any flags, this will clear completion for the given commands.  Are you sure you want to do this?  [Y/n - I meant to use the -p flag]"
		if [ "${REPLY,,}" == "n" ]; then
			dashp="yes"
			set -- -p "$@"
		fi
		echo
	fi
	if [ "${dashp}" == "yes" ]; then
		OUT="$(command complete "$@")"
		echo "${OUT}"
		fn="$(echo "${OUT}" | sed -nre 's/^complete -F ([^ ]+) .+/\1/p')"
		if [ -n "$fn" ]; then
			echo
			# shellcheck disable=SC2230 - which is non-standard, use command -v instead
			which "$fn"
		fi
	else
		command complete "$@"
	fi
}
