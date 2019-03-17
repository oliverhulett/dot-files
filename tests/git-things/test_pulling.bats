#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/pulling.sh"

@test "$FUT: pullme works like pull, mostly" {
	skip "Not implemented"
}

@test "$FUT: pushme will pull first if necessary" {
	skip "Not implemented"
}
