## A collection of utils to help testing with BATS

## Load bats libraries
function load_lib()
{
	source "$(dirname "${BASH_SOURCE[0]}")/x_helpers/$1/load.bash"
}

## Save any existing setup/teardown functions.  For use when a test file is about to define a local setup/teardown
## function but wants to be able to call any common "fixture" setup/teardown from within the local versions.
save_setup='{
	eval "__${BATS_TEST_FILENAME}_$(declare -f setup | echo "setup() { : ; }")";
	function _original_setup() { eval "__${BATS_TEST_FILENAME}_setup"; };
}'
save_teardown='{
	eval "__${BATS_TEST_FILENAME}_$(declare -f teardown | echo "teardown() { : ; }")";
	function _original_teardown() { eval "__${BATS_TEST_FILENAME}_teardown"; };
}'

## Set ${HOME} to a blank temporary dir incase tests want to mutate it.
function setup_blank_home()
{
	_ORIG_HOME="${HOME}"
	HOME="$(temp_make --prefix="home")"
	export HOME
}
function teardown_blank_home()
{
	if [ -z "${_ORIG_HOME}" ]; then
		fail "_ORIG_HOME not set; can't teardown blank home"
	fi
	if [ "${HOME#/home}" != "${HOME}" ]; then
		fail "HOME still contains /home; danger"
	fi
	temp_del "${HOME}"
	HOME="${_ORIG_HOME}"
	export HOME
}
