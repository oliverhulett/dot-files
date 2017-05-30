#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

TEST_FILE="bin/get-repo-dir.sh"

function setup()
{
	assert_prog
	scoped_blank_home
	REPO_DIR="${HOME}/repo"
	mkdir --parents "${REPO_DIR}"/proj1/repo1/master/folder1/folder2
	mkdir --parents "${REPO_DIR}"/proj1/repo1/branch1/folder1/folder2
	mkdir --parents "${REPO_DIR}"/proj1/repo2/master/folder1
	mkdir --parents "${REPO_DIR}"/proj2/repo2/master/folder2
	mkdir --parents "${REPO_DIR}"/proj2/repo2/branch2/folder2
}

@test "$TEST_FILE: requires at least one argument" {
	run "${EXE}"
	assert_failure
	args=
	for i in $(seq 5); do
		args="$args arg$i"
		## Args are supposed to be split
		# shellcheck disable=SC2086
		run "${EXE}" $args
		assert_success
		assert_output ""
	done
}

@test "$TEST_FILE: silent on no match" {
	run "${EXE}" repo1 branch2
	assert_success
	assert_output ""
	run "${EXE}" repo1 master folder2
	assert_success
	assert_output ""
	run "${EXE}" proj0 repo1 master
	assert_success
	assert_output ""
}

@test "$TEST_FILE: finds existing checkouts" {
	run "${EXE}" repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run "${EXE}" proj1 repo1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run "${EXE}" repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"
	run "${EXE}" proj1 repo1 master
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master"

	run "${EXE}" repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
	run "${EXE}" proj1 repo1 branch1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1"
}

@test "$TEST_FILE: finds existing folder in checkout" {
	run "$EXE" repo1 master folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run "$EXE" repo1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1"
	run "$EXE" repo1 branch1 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/branch1/folder1"
}

@test "$TEST_FILE: find nested folders" {
	run "$EXE" repo1 folder1 folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run "$EXE" repo1 folder1/folder2
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run "$EXE" repo1 folder1/folder2/
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
	run "$EXE" repo1 folder1/folder2//
	assert_success
	assert_output "${REPO_DIR}/proj1/repo1/master/folder1/folder2"
}

@test "$TEST_FILE: disambiguates by branch, then folder" {
	run "$EXE" repo2 branch2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/branch2"
	run "$EXE" repo2 folder1
	assert_success
	assert_output "${REPO_DIR}/proj1/repo2/master/folder1"
	run "$EXE" repo2 folder2
	assert_success
	assert_output "${REPO_DIR}/proj2/repo2/master/folder2"
}

@test "$TEST_FILE: prints all ambiguous choices" {
	run "$EXE" repo2
	assert_success
	assert_line "${REPO_DIR}/proj1/repo2/master"
	assert_line "${REPO_DIR}/proj2/repo2/master"
}
