#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/touch.sh"

@test "$FUT: touch a new file" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	run git touch file
	assert_status " A file"
	assert_files file
}

@test "$FUT: touch and existing file" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	touch file
	git add file
	git commitme -am"message"
	assert_files file
	run git touch file
	assert_status ""
	echo "words" >file
	assert_status " M file"
	run git touch file
	assert_status " M file"
}
