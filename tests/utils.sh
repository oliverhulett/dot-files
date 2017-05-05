## A collection of utils to help testing with BATS

## Load bats libraries
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-support/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-assert/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-file/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/bats-mock/stub.bash"

## Save any existing setup/teardown functions.  For use when a test file is about to define a local setup/teardown
## function but wants to be able to call any common "fixture" setup/teardown from within the local versions.
save_setup='{
	eval "__${BATS_TEST_FILENAME}_$(declare -f setup | echo "setup() { : ; }")";
	function saved_setup() { eval "__${BATS_TEST_FILENAME}_setup"; };
}'
save_teardown='{
	eval "__${BATS_TEST_FILENAME}_$(declare -f teardown | echo "teardown() { : ; }")";
	function saved_teardown() { eval "__${BATS_TEST_FILENAME}_teardown"; };
}'

## Set ${HOME} to a blank temporary dir incase tests want to mutate it.
function setup_blank_home()
{
	export _ORIG_HOME="${HOME}"
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
