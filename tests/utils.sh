## A collection of utils to help testing with BATS
# shellcheck shell=bash

## Load bats libraries
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-support/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-assert/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-file/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-mock/load.bash"

# Most of these functions only work in setup, teardown, or test functions
function _check_caller_is_test()
{
	if ! ( batslib_is_caller --indirect 'setup' \
			|| batslib_is_caller --indirect "$BATS_TEST_NAME" \
			|| batslib_is_caller --indirect 'teardown' )
	then
		echo "Must be called from \`setup', \`@test' or \`teardown'" \
			| batslib_decorate "ERROR: $*" \
			| fail
		return $?
	fi
}

# Skip the test if the program under test doesn't exist
# TODO:  What about aliases and functions?  May need to rename some things and re-work some messages.
function assert_fut()
{
	_check_caller_is_test assert_fut || return $?
	declare -g FUT_PATH
	FUT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(git home)" && echo "$(git home)/$(git ls-files -- "${FUT}")")"
	if [ ! -f "${FUT_PATH}" ]; then
		skip "Failed to find file under test"
		return 1
	fi
}
function assert_fut_exe()
{
	_check_caller_is_test assert_fut_exe || return $?
	if [ -n "${FUT}" ]; then
		assert_fut || return $?
		declare -g EXE="${FUT_PATH}"
		if [ ! -x "${EXE}" ]; then
			local shebang
			shebang="$(head -n1 "${EXE}")"
			local interpreter="${shebang:2}"
			if [ "${shebang:0:2}" != '#!' ] || [ ! -e "${interpreter%% *}" ]; then
				skip "Program under test is not executable or has an invalid shebang"
				return 1
			else
				EXE="${interpreter} $EXE"
			fi
		fi
	fi
}
# Default setup() is to skip the test if the program under test doesn't exist
function setup()
{
	assert_fut_exe
}

# Mechanism for registering clean-up functions
declare -ga _TEARDOWN_FNS
function register_teardown_fn()
{
	_TEARDOWN_FNS[${#_TEARDOWN_FNS[@]}]="$*"
}
function fire_teardown_fns()
{
	_check_caller_is_test fire_teardown_fns || return $?

	for fn in "${_TEARDOWN_FNS[@]}"; do
		$fn
	done
}
# Default teardown is to fire all registered clean-up functions
function teardown()
{
	fire_teardown_fns
}

# Set and export an environment variable and register it to be restored in teardown.
function scoped_env()
{
	_check_caller_is_test scoped_env || return $?
	for i in "$@"; do
		if [ "${i/=//}" == "$i" ]; then
			local var="$i"
			local val=
		else
			local var="${i%%=*}"
			local val="${i#*=}"
		fi
		if [ -z "${!var}" ]; then
			register_teardown_fn unset "${var}"
		else
			register_teardown_fn export "${var}"="$(eval echo "${!var}")"
		fi
		if [ -z "$val" ]; then
			val="$(eval echo "${!var}")"
		fi
		eval export "${var}"="${val}"
	done
}
function scoped_environment()
{
	scoped_env "$@"
}

# Create a temporary file or directory and register it for removal on teardown.
function scoped_mktemp()
{
	_check_caller_is_test scoped_mktemp || return $?
	local var="$1"
	shift
	local f
	f="$(mktemp -p "${BATS_TMPDIR}" "$@" "${BATS_TEST_NAME}".XXXXXXXX)"
	register_teardown_fn unset "${var}"
	register_teardown_fn rm -rf "$f"
	eval "${var}"="$f"
}

# Set ${HOME} to a blank temporary directory in-case tests want to mutate it.
function setup_blank_home()
{
	_check_caller_is_test setup_blank_home || return $?
	declare -g _ORIG_HOME="${HOME}"
	local tmphome
	tmphome="$(temp_make --prefix="home")"
	if [ -z "$tmphome" ] || [ "$tmphome" == "$HOME" ]; then
		fail "Failed to setup mock \$HOME"
		return $?
	else
		export HOME="$tmphome"
	fi
}
function teardown_blank_home()
{
	_check_caller_is_test teardown_blank_home || return $?
	# Paranoid about deleting $HOME.  `temp_del` should only delete things it created.
	# `fail` doesn't actually work here?
	if [ -z "${_ORIG_HOME}" ]; then
		fail "\$_ORIG_HOME not set; can't teardown blank home"
		return $?
	elif [ "${HOME}" == "${_ORIG_HOME}" ]; then
		fail "\$HOME wasn't changed; not deleting original \$HOME"
		return $?
	else
		temp_del "${HOME}"
	fi
	export HOME="${_ORIG_HOME}"
}
function scoped_blank_home()
{
	setup_blank_home
	register_teardown_fn teardown_blank_home
}

# A common pattern is to assert all lines of output.  Each argument is a line, in order.  All lines must be specified.
function assert_all_lines()
{
	_check_caller_is_test assert_all_lines || return $?
	local GLOBAL_REGEX_OR_PARTIAL=
	if [ "$1" == "--regexp" ] || [ "$1" == "--partial" ]; then
		GLOBAL_REGEX_OR_PARTIAL="$1"
		shift
	fi
	local errs=0
	local cnt=0
	for l in "$@"; do
		local LOCAL_REGEX_OR_PARTIAL
		LOCAL_REGEX_OR_PARTIAL="$(echo "$l" | cut -d' ' -f1)"
		if [ "$LOCAL_REGEX_OR_PARTIAL" == "--regexp" ] || [ "$LOCAL_REGEX_OR_PARTIAL" == "--partial" ]; then
			l="$(echo "$l" | cut -d' ' -f2-)"
		else
			LOCAL_REGEX_OR_PARTIAL=
		fi
		## Can't quote {GLOBAL,LOCAL}_REGEX_OR_PARTIAL because they'll be interpreted as "empty" lines and not match.
		# shellcheck disable=SC2086
		assert_line --index $cnt ${GLOBAL_REGEX_OR_PARTIAL} ${LOCAL_REGEX_OR_PARTIAL} "$l" || errs=$((errs + 1))
		cnt=$((cnt + 1))
	done
	## ${lines} is part of bash-support.
	# shellcheck disable=SC2154
	if [ $cnt -lt ${#lines[@]} ]; then
		(
			echo "Found more lines of output than expected.  Additional lines:"
			for idx in $(seq $cnt $((${#lines[@]} - 1))); do
				echo -e "\t> ${lines[$idx]}"
			done
		) | fail
		errs=$((errs + ${#lines[@]} - cnt))
	fi
	return $errs
}
