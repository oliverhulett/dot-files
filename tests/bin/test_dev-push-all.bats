#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="dev-push-all.sh"

function setup()
{
	assert_prog
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
}

@test "$PROG: expects at least one file or directory and zero or more servers" {
	stub ssh-ping.sh
	run $PROG
	assert_success
	assert_output ""
	unstub ssh-ping.sh

	stub ssh-ping.sh
	run $PROG server1:
	assert_success
	assert_output ""
	unstub ssh-ping.sh

	stub ssh-ping.sh " : echo server1"
	run $PROG "${TESTFILE}"
	assert_success
	assert_all_lines --partial "Server: server1" "ssh ${USER}@server1 "'" rm -v'
	unstub ssh-ping.sh
}

@test "$PROG: ignores localhost" {
	run $PROG server1: localhost: server2: "$(hostname -s)": server3: "${TESTFILE}"
	assert_success
	assert_all_lines --partial "Server: server1" "ssh ${USER}@server1 "'" rm -v' \
							   "Server: server2" "ssh ${USER}@server1 "'" rm -v' \
							   "Server: server3" "ssh ${USER}@server1 "'" rm -v'
}
