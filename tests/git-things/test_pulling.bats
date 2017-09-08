#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="git-things/bin/pulling.sh"

@test "$FUT: pullme works like pull, mostly" {
	fail "no done"
}

@test "$FUT: pushme will pull first if necessary" {
	fail "no done"
}
