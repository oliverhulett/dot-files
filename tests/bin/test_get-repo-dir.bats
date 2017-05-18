#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="bin/get-repo-dir.sh"

function setup()
{
	assert_prog
	scoped_blank_home
	REPO_DIR="${HOME}/repo"
	mkdir --parents ${REPO_DIR}/proj1/repo1/master/folder1/folder2
	mkdir --parents ${REPO_DIR}/proj1/repo1/branch1/folder1/folder2
	mkdir --parents ${REPO_DIR}/proj1/repo2/master/folder1
	mkdir --parents ${REPO_DIR}/proj2/repo2/master/folder2
	mkdir --parents ${REPO_DIR}/proj2/repo2/branch2/folder2
}

@test "$PROG: requires at least one argument" {
	run ${EXE}
	assert_failure
	args=
	for i in `seq 5`; do
		args="$args arg$i"
		run ${EXE} $args
		assert_success
		assert_output ""
	done
}

@test "$PROG: silent on no match" {
	run ${EXE} repo1 branch2
	assert_success
	assert_output ""
	run ${EXE} repo1 master folder2
	assert_success
	assert_output ""
	run ${EXE} proj0 repo1 master
	assert_success
	assert_output ""
}

@test "$PROG: finds existing checkouts" {
	run ${EXE} repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${EXE} proj1 repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${EXE} repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${EXE} proj1 repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"

	run ${EXE} repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
	run ${EXE} proj1 repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
}

@test "$PROG: finds existing folder in checkout" {
	run $EXE repo1 master folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run $EXE repo1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run $EXE repo1 branch1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1/folder1"
}

@test "$PROG: find nested folders" {
	run $EXE repo1 folder1 folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $EXE repo1 folder1/folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $EXE repo1 folder1/folder2/
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $EXE repo1 folder1/folder2//
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
}

@test "$PROG: disambiguates by branch, then folder" {
	run $EXE repo2 branch2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/branch2"
	run $EXE repo2 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo2/master/folder1"
	run $EXE repo2 folder2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/master/folder2"
}

@test "$PROG: prints all ambiguous choices" {
	run $EXE repo2
	assert_success
	assert_line "${REPO_DIR}/proj1/repo2/master"
	assert_line "${REPO_DIR}/proj2/repo2/master"
}
