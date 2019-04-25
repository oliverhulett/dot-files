#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/committing.sh"

@test "$FUT: no ticket on master" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	touch file
	git add file
	git commitme -am"message"
	run git log -1 --pretty=%B
	assert_all_lines "message"
}

@test "$FUT: prepend ticket if branch name encodes it" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	git checkout -b TKT-123/text
	touch file
	git add file
	git commitme -am"message"
	run git log -1 --pretty=%B
	assert_all_lines "TKT-123: message"
}
