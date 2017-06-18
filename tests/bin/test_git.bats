#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

FUT="bin/git"

@test "$FUT: calls underlying git" {
	stub git "one two three"
	run "${EXE}" one two three
	unstub git
}
