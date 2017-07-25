#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

FUT="bin/dev-push-all.sh"

function setup_dev_push_all()
{
	scoped_mktemp TEST_FILE_1 --suffix=.txt
	scoped_mktemp TEST_FILE_2 --suffix=.txt
	scoped_mktemp TEST_DIR_1 -d
	scoped_mktemp TEST_DIR_2 -d
}

@test "$FUT: expects at least one file or directory and zero or more servers" {
	alias ssh-list.sh="exit 1"
	run $EXE
	assert_success
	assert_output ""

	run $EXE server1:
	assert_success
	assert_output ""
	unalias ssh-list.sh

	SSH_ARGS="${USER}@server1 rm -v '$(dirname "${TEST_FILE_1}")'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' "
	RSYNC_ARGS="-zpPXrogthlcm ${TEST_FILE_1} ${USER}@server1:'$(dirname "${TEST_FILE_1}")/'"
	stub ssh-list.sh " : echo server1"
	stub ssh-name.sh ":server1 : echo server1"
	## bats-mock bug?  Args are too complex, perhaps?
	#stub ssh '*'
	#stub ssh "${SSH_ARGS}"
	stub rsync "${RSYNC_ARGS}"
	run $EXE "${TEST_FILE_1}"
	assert_success
	assert_all_lines "--partial Server: server1" "ssh ${SSH_ARGS}" "rsync ${RSYNC_ARGS}"
	unstub ssh-name.sh
	unstub ssh-list.sh
	#unstub ssh
	unstub rsync
}

@test "$FUT: ignores localhost" {
	SSH_ARGS_FMT="${USER}@server%d rm -v '$(dirname "${TEST_FILE_1}")'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' "
	RSYNC_ARGS_FMT="-zpPXrogthlcm ${TEST_FILE_1} ${USER}@server%d:'$(dirname "${TEST_FILE_1}")/'"
	stub ssh-name.sh ":server1 : echo server1" ":localhost : echo localhost" ":server2 : echo server2" ":$(hostname -s) : echo $(hostname -s)" ":server3 : echo server3"
	## bats-mock bug?
	#stub ssh "$(printf -- "${SSH_ARGS_FMT}" 1)" "$(printf -- "${SSH_ARGS_FMT}" 2)" "$(printf -- "${SSH_ARGS_FMT}" 3)"
	stub rsync "$(printf -- "${RSYNC_ARGS_FMT}" 1)" "$(printf -- "${RSYNC_ARGS_FMT}" 2)" "$(printf -- "${RSYNC_ARGS_FMT}" 3)"
	run $EXE server1: localhost: server2: "$(hostname -s)": server3: "${TEST_FILE_1}"
	assert_success
	assert_all_lines "--partial Server: server1" "ssh $(printf -- "${SSH_ARGS_FMT}" 1)" "rsync $(printf -- "${RSYNC_ARGS_FMT}" 1)" \
					 "--partial Server: server2" "ssh $(printf -- "${SSH_ARGS_FMT}" 2)" "rsync $(printf -- "${RSYNC_ARGS_FMT}" 2)" \
					 "--partial Server: server3" "ssh $(printf -- "${SSH_ARGS_FMT}" 3)" "rsync $(printf -- "${RSYNC_ARGS_FMT}" 3)"
	unstub ssh-name.sh
	#unstub ssh
	unstub rsync
}

@test "$FUT: groups input files and directories for shipping" {
	mkdir "${TEST_DIR_1}/dir1" "${TEST_DIR_2}/dir2"
	touch "${TEST_DIR_1}/file1" "${TEST_DIR_2}/file2" "${TEST_DIR_1}/dir1/file11" "${TEST_DIR_2}/dir2/file22"

	SSH_ARGS="${USER}@server1 rm -v '$(dirname "${TEST_FILE_1}")' '${TEST_DIR_1}' '${TEST_DIR_2}/dir2'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' '${TEST_DIR_1}' '${TEST_DIR_2}/dir2' "
	RSYNC_ARGS_FMT="-zpPXrogthlcm %s ${USER}@server1:'%s/'"
	stub ssh-name.sh ":server1 : echo server1"
	## bats-mock bug?
	#stub ssh "${SSH_ARGS}"
	stub rsync "$(printf -- "${RSYNC_ARGS_FMT}" "${TEST_FILE_1} ${TEST_FILE_2}" "$(dirname "$TEST_FILE_1")")" \
			   "$(printf -- "${RSYNC_ARGS_FMT}" "${TEST_DIR_1}/" "$TEST_DIR_1")" \
			   "$(printf -- "${RSYNC_ARGS_FMT}" "${TEST_DIR_2}/dir2/" "${TEST_DIR_2}/dir2")"
	run $EXE server1: "${TEST_FILE_1}" "${TEST_FILE_2}" "${TEST_DIR_1}" "${TEST_DIR_2}/dir2/"
	assert_success
	assert_all_lines "--partial Server: server1" "ssh ${SSH_ARGS}" \
					 "rsync $(printf -- "${RSYNC_ARGS_FMT}" "${TEST_FILE_1} ${TEST_FILE_2}" "$(dirname "$TEST_FILE_1")")" \
					 "rsync $(printf -- "${RSYNC_ARGS_FMT}" "${TEST_DIR_1}/" "$TEST_DIR_1")" \
					 "rsync $(printf -- "${RSYNC_ARGS_FMT}" "${TEST_DIR_2}/dir2/" "${TEST_DIR_2}/dir2")"
	unstub ssh-name.sh
	#unstub ssh
	unstub rsync
}

@test "$FUT: additional rsync arguments" {
	SSH_ARGS="${USER}@server1 rm -v '$(dirname "${TEST_FILE_1}")'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' "
	RSYNC_ARGS="-zpPXrogthlcm --rsync-arg1 -n ${TEST_FILE_1} ${USER}@server1:'$(dirname "${TEST_FILE_1}")/'"

	stub ssh-name.sh ":server1 : echo server1"
	## bats-mock bug?
	#stub ssh "${SSH_ARGS}"
	stub rsync "${RSYNC_ARGS}"
	run $EXE --rsync-arg1 server1: "${TEST_FILE_1}" -n
	assert_success
	assert_all_lines "--partial Server: server1" "ssh ${SSH_ARGS}" "rsync ${RSYNC_ARGS}"
	unstub ssh-name.sh
	#unstub ssh
	unstub rsync
}

@test "$FUT: respects ssh relaying" {
	SSH_ARGS_FMT="-o ProxyCommand ssh -W %%h:%%p relaysvr%d ${USER}@server%d rm -v '$(dirname "${TEST_FILE_1}")'  2>/dev/null; mkdir -pv '$(dirname "${TEST_FILE_1}")' "
	RSYNC_ARGS_FMT="-e ssh%srelaysvr%d' -zpPXrogthlcm ${TEST_FILE_1} ${USER}@server%d:'$(dirname "${TEST_FILE_1}")/'"
	stub ssh-name.sh "relaysvr1:server2 : echo server2" "relaysvr3:server4 : echo server4"
	## bats-mock bug?
	#stub ssh "$(printf -- "${SSH_ARGS_FMT}" 1 2)" "$(printf -- "${SSH_ARGS_FMT}" 3 4)"
	stub rsync "$(printf -- "${RSYNC_ARGS_FMT}" '*' 1 2)" "$(printf -- "${RSYNC_ARGS_FMT}" '*' 3 4)"
	run $EXE relaysvr1:server2: relaysvr3:server4: "${TEST_FILE_1}"
	assert_success
	assert_all_lines "--partial Server: server2" "ssh $(printf -- "${SSH_ARGS_FMT}" 1 2)" "--regexp rsync $(printf -- "${RSYNC_ARGS_FMT}" '.+' 1 2)" \
					 "--partial Server: server4" "ssh $(printf -- "${SSH_ARGS_FMT}" 3 4)" "--regexp rsync $(printf -- "${RSYNC_ARGS_FMT}" '.+' 3 4)"
	unstub ssh-name.sh
	#unstub ssh
	unstub rsync
}
