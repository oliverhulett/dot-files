#!/usr/bin/env bats

DOTFILES="$(dirname "${BATS_TEST_DIRNAME}")"

## Tests _hidex and _restorex
@test "_hidex unsets -x and remembers incoming value" {
	source "${DOTFILES}/bash_common.sh"
	set -x
	run eval "${_hidex}"
	[[ $- != *x* ]]
	set +x
	echo $status
#	[ $status -eq 0 ]
	[ -z "$output" ]
}
