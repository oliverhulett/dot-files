#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

FUT="bin/clone.sh"

function setup_clone()
{
	GIT_URL_BASE="ssh://git@git.comp.optiver.com:7999"
	REPO_DIR="${HOME}/repo"
}

@test "$FUT: requires two arguments" {
	run "${EXE}"
	assert_failure
	run "${EXE}" arg1
	assert_failure
	run "${EXE}" arg1 arg2 arg3
	assert_failure

	run "${EXE}" --cpp
	assert_failure
	run "${EXE}" --cpp arg1
	assert_failure
	run "${EXE}" --cpp arg1 arg2 arg3
	assert_failure
}

@test "$FUT: clones master and copies Eclipse project files" {
	stub git "clone --recursive ${GIT_URL_BASE}/repo1/proj1.git master : mkdir master" "update"
	run "${EXE}" repo1 proj1
	assert_success
	unstub git

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.project" ]
}

@test "$FUT: doesn't clone existing checkouts" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	touch "${REPO_DIR}/repo1/proj1/master/.project"
	stub git
	run "${EXE}" repo1 proj1
	assert_success
	unstub git
}

@test "$FUT: failes if clone fails" {
	stub git "clone --recursive ${GIT_URL_BASE}/repo1/proj1.git master : false"
	run "${EXE}" repo1 proj1
	assert_failure
	unstub git

	assert [ ! -e "${REPO_DIR}/repo1/proj1/master" ]
	assert [ ! -e "${REPO_DIR}/repo1/proj1" ]
	assert [ ! -e "${REPO_DIR}/repo1" ]
}

@test "$FUT: detects C++ projects" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	touch "${REPO_DIR}/repo1/proj1/master/CMakeLists.txt"
	run "${EXE}" repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.cproject" ]
}

@test "$FUT: detects GOLANG projects" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master/src"
	run "${EXE}" repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.settings/com.googlecode.goclipse.core.prefs" ]
}

@test "$FUT: falls-back to Python project" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	run "${EXE}" repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.pydevproject" ]
}

@test "$FUT: can override project type" {
	mkdir --parent "${REPO_DIR}/repo1/cpp-proj/master"
	mkdir --parent "${REPO_DIR}/repo1/go-proj/master"
	mkdir --parent "${REPO_DIR}/repo1/py-proj/master"

	run "${EXE}" repo1 cpp-proj --cpp
	assert_success
	assert [ -e "${REPO_DIR}/repo1/cpp-proj/master/.cproject" ]

	run "${EXE}" repo1 go-proj --go
	assert_success
	assert [ -e "${REPO_DIR}/repo1/go-proj/master/.settings/com.googlecode.goclipse.core.prefs" ]

	run "${EXE}" repo1 py-proj --py
	assert_success
	assert [ -e "${REPO_DIR}/repo1/py-proj/master/.pydevproject" ]
}
