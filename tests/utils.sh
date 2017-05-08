## A collection of utils to help testing with BATS

## Load bats libraries
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-support/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-assert/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-file/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-mock/stub.bash"

function find_prog()
{
	basename -- "$(command which "$1" 2>/dev/null || command which "${1%.*}" 2>/dev/null)" 2>/dev/null
}
function assert_prog()
{
	if [ -n "${PROG}" ]; then
		PROG="$(find_prog "${PROG}")"
		if [ -z "${PROG}" ]; then
			skip "Failed to find program under test"
		fi
	fi
}
function setup()
{
	assert_prog
}

function _check_caller()
{
	if ! ( batslib_is_caller --indirect 'setup' \
			|| batslib_is_caller --indirect "$BATS_TEST_NAME" \
			|| batslib_is_caller --indirect 'teardown' )
	then
		echo "Must be called from \`setup', \`@test' or \`teardown'" \
			| batslib_decorate "ERROR: $1" \
			| fail
		return $?
	fi
}

declare -ga _TEARDOWN_FNS
function register_teardown_fn()
{
	_check_caller register_teardown_fn || return $?

	_TEARDOWN_FNS[${#_TEARDOWN_FNS[@]}]="$*"
}
function fire_teardown_fns()
{
	_check_caller fire_teardown_fns || return $?

	for fn in "${_TEARDOWN_FNS[@]}"; do
		$fn
	done
}
function teardown()
{
	fire_teardown_fns
}

## Set ${HOME} to a blank temporary dir incase tests want to mutate it.
function setup_blank_home()
{
	_check_caller setup_blank_home || return $?
	declare -g _ORIG_HOME="${HOME}"
	tmphome="$(temp_make --prefix="home")"
	if [ -z "$tmphome" ] || [ "$tmphome" == "$HOME" ]; then
		fail "Failed to setup mock \$HOME"
	else
		export HOME="$tmphome"
	fi
}
function teardown_blank_home()
{
	_check_caller teardown_blank_home || return $?
	# Paranoid about deleting $HOME.  `temp_del` should only delete things it created.
	# `fail` doesn't actually work here?
	if [ -z "${_ORIG_HOME}" ]; then
		fail "\$_ORIG_HOME not set; can't teardown blank home"
	elif [ "${HOME}" == "${_ORIG_HOME}" ]; then
		fail "\$HOME wasn't changed; not deleting original \$HOME"
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
