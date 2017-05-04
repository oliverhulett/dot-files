#!/usr/bin/env bats

PROG="get-repo-dir.sh"

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

load_lib bats-support
load_lib bats-assert
load_lib bats-file

_run_tag="__${RANDOM}"
eval "${_run_tag}_$(declare -f setup | echo "setup () { : ; }")"
function setup()
{
	eval "${_run_tag}_setup"
	_ORIG_HOME="${HOME}"
	HOME="$(temp_make)"
	BATSLIB_FILE_PATH_REM="#${HOME}"
	BATSLIB_FILE_PATH_ADD='<home>'
	REPO_DIR="${HOME}/repo"
	mkdir --parents ${REPO_DIR}/proj1/repo1/master/folder1/folder2
	mkdir --parents ${REPO_DIR}/proj1/repo1/branch1/folder1/folder2
	mkdir --parents ${REPO_DIR}/proj1/repo2/master/folder1
	mkdir --parents ${REPO_DIR}/proj2/repo2/master/folder2
	mkdir --parents ${REPO_DIR}/proj2/repo2/branch2/folder2
	export HOME
}
eval "${_run_tag}_$(declare -f teardown | echo "teardown () { : ; }")"
function teardown()
{
	temp_del "${HOME}"
	export HOME="${_ORIG_HOME}"
	eval "${_run_tag}_teardown"
}

@test "$PROG: requires at least one argument" {
	run ${PROG}
	assert_failure
	args=
	for i in `seq 5`; do
		args="$args arg$i"
		run ${PROG} $args
		assert_success
		assert_output ""
	done
}

@test "$PROG: silent on no match" {
	run ${PROG} repo1 branch2
	assert_success
	assert_output ""
	run ${PROG} repo1 master folder2
	assert_success
	assert_output ""
	run ${PROG} proj0 repo1 master
	assert_success
	assert_output ""
}

@test "$PROG: finds existing checkouts" {
	run ${PROG} repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${PROG} proj1 repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${PROG} repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run ${PROG} proj1 repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"

	run ${PROG} repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
	run ${PROG} proj1 repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
}

@test "$PROG: finds existing folder in checkout" {
	run $PROG repo1 master folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run $PROG repo1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run $PROG repo1 branch1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1/folder1"
}

@test "$PROG: find nested folders" {
	run $PROG repo1 folder1 folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $PROG repo1 folder1/folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $PROG repo1 folder1/folder2/
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run $PROG repo1 folder1/folder2//
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
}

@test "$PROG: disambiguates by branch, then folder" {
	run $PROG repo2 branch2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/branch2"
	run $PROG repo2 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo2/master/folder1"
	run $PROG repo2 folder2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/master/folder2"
}

@test "$PROG: prints all ambiguous choices" {
	run $PROG repo2
	assert_success
	assert_line "${REPO_DIR}/proj1/repo2/master"
	assert_line "${REPO_DIR}/proj2/repo2/master"
}
