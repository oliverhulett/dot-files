#!/usr/bin/env bash

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
DF_TESTS="$(dirname "${HERE}")"
source "${DF_TESTS}/utils.sh"

function setup_git_things()
{
	scoped_mktemp BARE_REPO -d
	scoped_mktemp CHECKOUT -d
	( cd "${BARE_REPO}" && git init --bare )
	( cd "${CHECKOUT}" && git clone "${BARE_REPO}" repo )
	( cd "${CHECKOUT}/repo" && touch nothing && git add nothing && git commit -m"nothing" && git upstream )

	source "${DOTFILES}/bash-aliases/15-env-git.sh"
}

function assert_files()
{
	assert_equal "$(find ./ -xdev -not -name '.' -not \( -name '.git' -prune \) -print | sort)" \
				 "$(printf "./%s\n" "nothing" "$@" | sort -u)"
}

function assert_contents()
{
	run command cat "$1"
	shift
	assert_all_lines "$@"
}

function assert_status()
{
	run git status -s
	assert_all_lines "$@"
}
