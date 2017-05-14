#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="clone.sh"

function setup()
{
	assert_prog
	scoped_blank_home
	GIT_URL_BASE="ssh://git@git.comp.optiver.com:7999"
	REPO_DIR="${HOME}/repo"
}

@test "$PROG: requires two arguments" {
	run ${PROG}
	assert_failure
	run ${PROG} arg1
	assert_failure
	run ${PROG} arg1 arg2 arg3
	assert_failure
}

@test "$PROG: clones master and copies Eclipse project files" {
	stub git "clone --recursive ${GIT_URL_BASE}/repo1/proj1.git master : mkdir master" "update"
	run ${PROG} repo1 proj1
	assert_success
	unstub git

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.project" ]
}

@test "$PROG: doesn't clone existing checkouts" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	touch "${REPO_DIR}/repo1/proj1/master/.project"
	stub git
	run ${PROG} repo1 proj1
	assert_success
	unstub git
}

@test "$PROG: failes if clone fails" {
	stub git "clone --recursive ${GIT_URL_BASE}/repo1/proj1.git master : false"
	run ${PROG} repo1 proj1
	assert_failure
	unstub git

	assert [ ! -e "${REPO_DIR}/repo1/proj1/master" ]
	assert [ ! -e "${REPO_DIR}/repo1/proj1" ]
	assert [ ! -e "${REPO_DIR}/repo1" ]
}

@test "$PROG: detects C++ projects" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	touch "${REPO_DIR}/repo1/proj1/master/CMakeLists.txt"
	run ${PROG} repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.cproject" ]
}

@test "$PROG: detects GOLANG projects" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master/src"
	run ${PROG} repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.settings/com.googlecode.goclipse.core.prefs" ]
}

@test "$PROG: falls-back to Python project" {
	mkdir --parents "${REPO_DIR}/repo1/proj1/master"
	run ${PROG} repo1 proj1
	assert_success

	assert [ -e "${REPO_DIR}/repo1/proj1/master/.pydevproject" ]
}
