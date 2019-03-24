#!/usr/bin/env bats
# shellcheck disable=SC2016 - Expressions don't expand in single quotes.

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

## Custom `command_not_found_handle`.
export FUT="bash-aliases/45-setup-command_not_found_handle.sh"
export IS_EXE="false"

function _source()
{
	source "${FUT}"
	#shellcheck disable=SC2034 - unused verify or export
	typeset -fx command_not_found_handle
	#shellcheck disable=SC2034 - unused verify or export
	typeset -fx _do_cnfh
	#shellcheck disable=SC2034 - unused verify or export
	typeset -fx _find_bootstrapper
	eval '_run_bootstrapper() {
		echo "_run_bootstrapper";
	}'
	#shellcheck disable=SC2034 - unused verify or export
	typeset -fx _run_bootstrapper
}

function setup_command_not_found_handle()
{
	eval '__original_command_not_found_handle() {
		echo "__original_command_not_found_handle: $@";
	}'
	#shellcheck disable=SC2034 - unused verify or export
	typeset -fx __original_command_not_found_handle
	_source
}

@test "$FUT: install handle override" {
	unset __original_command_not_found_handle
	unset command_not_found_handle
	_source
	run test -n "$(declare -f command_not_found_handle)"
	assert_success
	run test -z "$(declare -f __original_command_not_found_handle)"
	assert_success

	eval 'command_not_found_handle() {
		echo;
	}'
	_source
	run declare -f __original_command_not_found_handle
	assert_success
	assert_all_lines "__original_command_not_found_handle () " \
					 "{ " \
					 "    echo" \
					 "}"
	run test -n "$(declare -f command_not_found_handle)"
	assert_success

	CNFH="$(declare -f command_not_found_handle)"
	OCNFH="$(declare -f __original_command_not_found_handle)"
	_source
	assert_equal "$(declare -f command_not_found_handle)" "${CNFH}"
	assert_equal "$(declare -f __original_command_not_found_handle)" "${OCNFH}"
}

@test "$FUT: if no caller, fallback to default handler" {
	run notfound with args
	assert_all_lines "__original_command_not_found_handle: notfound with args" \
					 "_run_bootstrapper"
}

@test "$FUT: if no default handler, suggest instaling one for this platform" {
	unset __original_command_not_found_handle
	run notfound with args
	assert_all_lines "The program 'notfound' is currently not installed." \
					 "No 'command_not_found_handle' installed.  You can install it by typing:" \
					 "  brew tap homebrew/command-not-found" \
					 '  eval "$(brew command-not-found-init)"' \
					 '  source "~/.bash-aliases/05-profile.d-command_not_found.sh"' \
					 "_run_bootstrapper"
}

# TODO:  Add validation that bootstrapper files have corresponding command script or function.

## Skip these things, we can't actually do it like this.
## We'll have to integrate this idea with command prompt fn.
#@test "$FUT: look for bootstrapper file for caller and suggest calling it" {
#	scoped_mktemp DIR -d
#	SCRIPT="${DIR}/script.sh"
#	BOOTSTRAPPER="${DIR}/.bootstraps/script.sh"
#	cat - >"${SCRIPT}" <<-EOF
#		#!/usr/bin/env bash
#		notfound
#	EOF
#	mkdir -p "${DIR}/.bootstraps/"
#	touch "${BOOTSTRAPPER}"
#	chmod +x "${SCRIPT}" "${BOOTSTRAPPER}"
#	run "${SCRIPT}" with args
#	assert_all_lines "The script '${SCRIPT}' is trying to run the program 'notfound', which is not currently installed." \
#					 "You can install all of the dependencies for '${SCRIPT}' by typing:" \
#					 "  ${BOOTSTRAPPER}" \
#					 "_run_bootstrapper"
#}
#
#@test "$FUT: walk up the stack to find bootstrapper file" {
#	scoped_mktemp DIR -d
#	SCRIPT_ONE="${DIR}/script_one.sh"
#	SCRIPT_TWO="${DIR}/script_two.sh"
#	BOOTSTRAPPER="${DIR}/.bootstraps/script_one.sh"
#	cat - >"${SCRIPT_ONE}" <<-EOF
#		#!/usr/bin/env bash
#		source ${SCRIPT_TWO}
#	EOF
#	cat - >"${SCRIPT_TWO}" <<-EOF
#		#!/usr/bin/env bash
#		notfound
#	EOF
#	mkdir -p "${DIR}/.bootstraps/"
#	touch "${BOOTSTRAPPER}"
#	chmod +x "${SCRIPT_ONE}" "${SCRIPT_TWO}" "${BOOTSTRAPPER}"
#	run "${SCRIPT_ONE}" with args
#	assert_all_lines "The script '${SCRIPT_ONE}' is trying to run the program 'notfound', which is not currently installed." \
#					 "You can install all of the dependencies for '${SCRIPT_ONE}' by typing:" \
#					 "  ${BOOTSTRAPPER}" \
#					 "_run_bootstrapper"
#}
#
#@test "$FUT: if no bootstrapper file, suggest writing one and fallback to default handler" {
#	scoped_mktemp SCRIPT --suffix=.sh
#	BOOTSTRAPPER="$(dirname "${SCRIPT}")/.bootstraps/$(basename -- "${SCRIPT}")"
#	cat - >"${SCRIPT}" <<-EOF
#		#!/usr/bin/env bash
#		notfound not found args
#	EOF
#	chmod +x "${SCRIPT}"
#	run "${SCRIPT}" with args
#	assert_all_lines "The script '${SCRIPT}' is trying to run the program 'notfound', which is not currently installed." \
#					 "You can write a bootstrapper for '${SCRIPT}' by implementing '${BOOTSTRAPPER}'" \
#					 "__original_command_not_found_handle nottfound not found args" \
#					 "_run_bootstrapper"
#}
