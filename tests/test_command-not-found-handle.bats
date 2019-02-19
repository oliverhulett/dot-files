#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

## Custom `command_not_found_handle`.
export FUT="bash-aliases/45-setup-command_not_found.sh"
export IS_EXE="false"

function setup_command_not_found_handle()
{
	eval 'command_not_found_handle() { echo command_not_found_handle; }'
	source "${DOTFILES}/${FUT}"
}

# TODO:  Add validation that bootstrapper files have corresponding command script or function.

@test "$FUT: look for bootstrapper file for caller and suggest calling it" {
	skip "not implemented yet"
}

@test "$FUT: if no caller, fallback to default handler" {
	skip "not implemented yet"
	run notfound
	assert_all_lines "notfound: command not found"
	fail
}

@test "$FUT: if no bootstrapper file, suggest writing one and fallback to default handler" {
	skip "not implemented yet"
}

@test "$FUT: if no default handler, suggest instaling one for this platform" {
	unset __original_command_not_found_handle
	unset command_not_found_handle
	source "${DOTFILES}/${FUT}"
	stub brew "tap homebrew/command-not-found" "command-not-found-init"
	stub eval
	stub read
	run notfound
	# shellcheck disable=SC2016 - Expressions don't expand in single quotes.
	# `read` prompt is printed to stderr, won't show up here.
	assert_all_lines "The program 'notfound' is currently not installed." \
					 "No 'command_not_found_handle' installed.  You can install it by typing:" \
					 "  brew tap homebrew/command-not-found" \
					 '  eval "$(brew command-not-found-init)"' \
					 '  source "'"${DOTFILES}/${FUT}"'"' \
					 "$ brew tap homebrew/command-not-found" \
					 '$ eval "$(brew command-not-found-init)"' \
					 '$ source "'"${DOTFILES}/${FUT}"'"'
}

@test "$FUT: install handle override" {
	unset __original_command_not_found_handle
	unset command_not_found_handle
	source "${DOTFILES}/${FUT}"
	run test -n "$(declare -f command_not_found_handle)"
	assert_success
	run test -z "$(declare -f __original_command_not_found_handle)"
	assert_success

	eval 'command_not_found_handle() {
		echo;
	}'
	source "${DOTFILES}/${FUT}"
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
	source "${DOTFILES}/${FUT}"
	assert_equal "$(declare -f command_not_found_handle)" "${CNFH}"
	assert_equal "$(declare -f __original_command_not_found_handle)" "${OCNFH}"
}
