#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="dev-push-all.sh"

function setup()
{
	assert_prog
	scoped_mktemp TEST_FILE_1 --suffix=.txt
	scoped_mktemp TEST_DIR_1 -d
}

@test "$PROG: expects at least one file or directory and zero or more servers" {
	alias ssh-ping.sh="exit 1"
	run $PROG
	assert_success
	assert_output ""

	run $PROG server1:
	assert_success
	assert_output ""
	unalias ssh-ping.sh

	stub ssh-ping.sh " : echo server1"
	SSH_ARGS="${USER}@server1 rm -v '$(dirname "${TEST_FILE_1}")'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' "
#	stub ssh '* : true'
	RSYNC_ARGS="-zpPXrogthlcm ${TEST_FILE_1} ${USER}@server1:'$(dirname "${TEST_FILE_1}")/'"
	stub rsync "${RSYNC_ARGS} : exit 0"
	run $PROG "${TEST_FILE_1}"
	assert_success
	assert_all_lines --partial "Server: server1" "ssh ${SSH_ARGS}" "rsync ${RSYNC_ARGS}"
	unstub ssh-ping.sh
#	unstub ssh
	unstub rsync
}

#@test "$PROG: ignores localhost" {
#	run $PROG server1: localhost: server2: "$(hostname -s)": server3: "${TEST_FILE_1}"
#	assert_success
#	assert_all_lines --partial "Server: server1" "ssh ${USER}@server1 "'" rm -v' \
#							   "Server: server2" "ssh ${USER}@server1 "'" rm -v' \
#							   "Server: server3" "ssh ${USER}@server1 "'" rm -v'
#}
