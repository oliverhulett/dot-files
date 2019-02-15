#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

## Custom `command_not_found_handle`.
## Walk up the caller stack looking for executables that have matching bootstrapper files.
##  If found, offer to run the bootstrapper file, run it if yes.
## Fallback to the default command_not_found_handle, parse output for suggested installation command, offer to run it, run it if yes.
## If no default command_not_found_handle, offer to install it, install if yes.
export FUT="command_not_found_handle"

function setup_command_not_found_handle()
{
	:
}

# TODO:  Add validation that bootstrapper files have corresponding command script or function.

@test "$FUT: look for bootstrapper file for caller and suggest calling it" {
	:
}

@test "$FUT: if no caller, fallback to default handler" {
	run notfound
	assert_all_lines "notfound: command not found"
}

@test "$FUT: if no bootstrapper file, suggest writing one and fallback to default handler" {
:
}

@test "$FUT: if no default handler, suggest instaling one for this platform" {
	unset _default_command_not_found_handle
	run notfound
	assert_all_lines "notfound: command not found" \
					 "command_not_found_handle: not found.  Try \`brew tap homebrew/command-not-found'"
}
