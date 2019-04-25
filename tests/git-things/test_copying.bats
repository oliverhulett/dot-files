#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/copying.sh"

@test "$FUT: copy a single file" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	touch file
	git add file
	git commitme -am"message"
	run git cp file copy
	assert_status "A  copy"
	assert_files file copy
}

@test "$FUT: copy multiple files to a directory" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	touch file1 file2
	git add file1 file2
	git commitme -am"message"
	mkdir copies
	run git cp file1 file2 copies
	assert_status "A  copies/file1" \
				  "A  copies/file2"
	assert_files file1 file2 copies copies/file1 copies/file2
}
