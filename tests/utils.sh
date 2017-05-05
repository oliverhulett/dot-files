## A collection of utils to help testing with BATS

## Load bats libraries
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-support/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-assert/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-file/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-mock/stub.bash"

declare -a _SETUP_FNS
function register_setup_fn()
{
	_SETUP_FNS[${#_SETUP_FNS[@]}]="$*"
}
function setup()
{
echo ${#_SETUP_FNS[@]}
set -x
	for fn in "${_SETUP_FNS[@]}"; do
		$fn
	done
set +x
}
declare -a _TEARDOWN_FNS
function register_teardown_fn()
{
	_TEARDOWN_FNS[${#_TEARDOWN_FNS[@]}]="$*"
}
function teardown()
{
	for fn in "${_TEARDOWN_FNS[@]}"; do
		$fn
	done
}

## Set ${HOME} to a blank temporary dir incase tests want to mutate it.
function setup_blank_home()
{
	declare -g _ORIG_HOME="${HOME}"
	export HOME="$(temp_make --prefix="home")"
}
function teardown_blank_home()
{
	# Paranoid about deleting $HOME.  `temp_del` should only delete things it created.
	# `fail` doesn't actually work here.
	if [ -z "${_ORIG_HOME}" ]; then
		fail "_ORIG_HOME not set; can't teardown blank home"
	elif [ "${HOME#/home}" != "${HOME}" ]; then
		fail "HOME still contains /home; danger"
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
