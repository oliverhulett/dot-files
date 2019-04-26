#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

export FUT="git-things/bin/cleaning.sh"

function setup_cleaning()
{
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	git ignoreme build node_modules
}

@test "$FUT: cleanignored" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	mkdir --parents .idea node_modules build
	touch .idea/file-to-keep node_modules/file-to-delete build/ignored-file-to-delete
	run git cleanme
	assert_success
	run test -e .idea/file-to-keep
	assert_success
	run test -e node_modules/file-to-delete
	assert_failure
	run test -e build/ignored-file-to-delete
	assert_failure
}

@test "$FUT: cleanall" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	echo '#!/bin/bash' >gradlew
	echo 'echo "stubbed $@"' >>gradlew
	chmod +x gradlew
	stub stubbed
	run git cleanme -a
	assert_success
	unstub stubbed
}
