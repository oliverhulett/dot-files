#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/which.sh"

@test "$FUT: git cleanbranches" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	git checkout -b testbranch
	run git branch
	assert_all_lines "  master" "* testbranch"

	git upstream

	git checkout -b testbranch2
	run git branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	git upstream

	git cleanbranches
	run git branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	git checkout master
	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git cleanbranches
	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git push origin --delete testbranch
	git fetch --prune

	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git cleanbranches
	run git branch
	assert_all_lines "* master" "  testbranch2"

	git push origin --delete testbranch2
	git pullme
	run git branch
	assert_all_lines "* master"
}
