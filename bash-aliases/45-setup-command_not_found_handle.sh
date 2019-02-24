# shellcheck shell=bash

DOTFILES="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)")"
# Save original command not found handle and install this one instead.  Needs to be idempotent.
if [ -n "$(declare -f command_not_found_handle)" ] && [ -z "$(declare -f __original_command_not_found_handle)" ]; then
	eval "__original_$(declare -f command_not_found_handle)"
fi
function command_not_found_handle()
{
	"${DOTFILES}/lib/command_not_found_handle.sh" "$@"
}
