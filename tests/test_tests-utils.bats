#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"

PROG="utils.sh"

function setup()
{
	unset _TEARDOWN_FNS
	unset _ORIG_HOME
}

_assert_all_lines_test_cnt=1
function _do_assert_all_lines_test()
{
	expected_errors=$1
	shift
	set +e; output="$(assert_all_lines "$@" 2>&1)"; retval=$?; set -e
	assert_equal $retval $expected_errors || echo -e "Failed expectation #${_assert_all_lines_test_cnt}:  Test args: $*\n${output}" | fail
	_assert_all_lines_test_cnt=$((_assert_all_lines_test_cnt + 1))
}
@test "$PROG: assert_all_lines" {
	source "${DF_TESTS}/utils.sh"
	run echo -e $' line1\nline 2\nline3 '
	# Note that this pattern is required to get the return value but not fail the test when assert_all_lines is expected to fail.
	_do_assert_all_lines_test 0 " line1" "line 2" "line3 "
	_do_assert_all_lines_test 1 "line1" "line 2" "line3 "
	_do_assert_all_lines_test 1 " line1" "line 2" "line3"
	_do_assert_all_lines_test 2 "line1" "line 2" "line3"
	_do_assert_all_lines_test 3 "line1" "line 2" "line3" "line 4"
	_do_assert_all_lines_test 4 "line1" "line 2" "line3" "line 4" "5"
	# All the lines are wrong because "line0" throws off the indicies.
	_do_assert_all_lines_test 4 "line0" " line1" "line 2" "line3 "
	_do_assert_all_lines_test 0 " line1" "line 2" "line3 "
	_do_assert_all_lines_test 1 " line1" "line 2"
	_do_assert_all_lines_test 2 " line1"
	# All the lines are wrong because the missing " line 1" throws off the indicies.
	_do_assert_all_lines_test 3 "line 2" "line3 "
	_do_assert_all_lines_test 1 " line1" "line 2" "line3 " "line4"
	_do_assert_all_lines_test 0 --regexp "^ line.$" "^li.e 2$" "^li..3 $"
	_do_assert_all_lines_test 0 --partial "ine" "lin" "ne3"
	# --partial and --regexp flags have to be ignored for missing expectations (AKA extra lines of output.)
	_do_assert_all_lines_test 1 --partial " line1" "line 2"
	_do_assert_all_lines_test 0 " line1" "--regexp ^line.+$" "--partial ine"
	_do_assert_all_lines_test 0 "--regexp line1$" "line 2" "line3 "
	# --partial does not start at character 0 of the third arg, so assert_all_lines can't be sure it's not part of the line to match.
	_do_assert_all_lines_test 1 " line1" "line 2" " --partial ine"
	run echo -n
	_do_assert_all_lines_test 0
}

@test "$PROG: finding programs" {
	source "${DF_TESTS}/utils.sh"
	run find_prog
	assert_failure

	run find_prog echo
	assert_success
	assert_output "echo"

	run find_prog echo.sh
	assert_success
	assert_output "echo"

	run find_prog none
	assert_success
	assert_output ""

	run find_prog /dev/null
	assert_success
	assert_output ""

	run find_prog "$(find_prog echo)"
	assert_success
	assert_output "echo"

	run find_prog "$(find_prog echo.sh)"
	assert_success
	assert_output "echo"
}

@test "$PROG: register teardown functions" {
	source "${DF_TESTS}/utils.sh"
	run teardown
	assert_success
	assert_output ""

	register_teardown_fn echo this
	run teardown
	assert_success
	assert_output "this"

	register_teardown_fn echo that
	run teardown
	assert_success
	assert_all_lines "this" "that"
}

@test "$PROG: scoped temporary files and directories are removed on teardown" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp tstfile1
	assert [ -n "$tstfile1" ]
	assert [ -e "$tstfile1" ]
	scoped_mktemp tstfile2 -d
	assert [ -n "$tstfile2" ]
	assert [ -d "$tstfile2" ]
	scoped_mktemp tstfile3 --suffix=.txt
	assert [ -n "$tstfile3" ]
	assert [ -e "$tstfile3" ]
	assert [ "${tstfile3%.txt}" != "${tstfile3}" ]

	run teardown

	assert [ ! -e "$tstfile1" ]
	assert [ ! -e "$tstfile2" ]
	assert [ ! -e "$tstfile3" ]
}

@test "$PROG: assert program exists" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp TESTFILE --suffix=.bats
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	@test "test" {
		true
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 test"

	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	PROG=none
	@test "test" {
		true
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 # skip (Failed to find program under test) test"

	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	PROG=echo.sh
	@test "test" {
		true
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 test"
}

@test "$PROG: simple test file" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	function setup()
	{
		echo "setup world" >>${OUTPUT}
		register_teardown_fn echo "registered teardown world"
	}
	function teardown()
	{
		fire_teardown_fns >>${OUTPUT}
		echo "teardown world" >>${OUTPUT}
	}
	@test "test" {
		echo "hello world" >>${OUTPUT}
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_success
	run cat $OUTPUT
	assert_all_lines "setup world" "hello world" "registered teardown world" "teardown world"
}

@test "$PROG: blank \$HOME" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	TMPHOME="$(mktemp -p "${BATS_TMPDIR}" --suffix=home --dry-run ${BATS_TEST_NAME}.XXXXXXXX)"
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	@test "test" {
		rm ${OUTPUT} || true
		exec >>${OUTPUT}
		exec 2>>${OUTPUT}
		unset -f temp_make
		unset -f temp_del
		unset -f fail
		echo "Before: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
		setup_blank_home
		echo "During: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
		teardown_blank_home
		echo "After: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
	}
	EOF

	stub temp_make '--prefix=home : echo "'${TMPHOME}'"'
	stub temp_del "${TMPHOME}"
	stub fail
	run bats -t "${TESTFILE}"
	assert_success
	run cat $OUTPUT
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME=" \
					 "During: HOME=${TMPHOME} _ORIG_HOME=${HOME}" \
					 "After: HOME=${HOME} _ORIG_HOME=${HOME}"
	unstub temp_make
	unstub temp_del
	unstub fail

	stub temp_make '--prefix=home : echo "'${HOME}${TMPHOME}'"'
	stub temp_del "${HOME}${TMPHOME}"
	stub fail
	run bats -t "${TESTFILE}"
	assert_success
	run cat $OUTPUT
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME=" \
					 "During: HOME=${HOME}${TMPHOME} _ORIG_HOME=${HOME}" \
					 "After: HOME=${HOME} _ORIG_HOME=${HOME}"
	unstub temp_make
	unstub temp_del
	unstub fail

	stub temp_make '--prefix=home : echo'
	stub temp_del
	stub fail '* : false'
	run bats -t "${TESTFILE}"
	assert_failure
	run cat $OUTPUT
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME="
	unstub temp_make
	unstub temp_del
	unstub fail

	stub temp_make '--prefix=home : echo "'${HOME}'"'
	stub temp_del
	stub fail '* : false'
	run bats -t "${TESTFILE}"
	assert_failure
	run cat $OUTPUT
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME="
	unstub temp_make
	unstub temp_del
	unstub fail
}

@test "$PROG: scoped blank \$HOME" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	TMPHOME="$(mktemp -p "${BATS_TMPDIR}" --suffix=home --dry-run ${BATS_TEST_NAME}.XXXXXXXX)"
	stub temp_make '--prefix=home : echo "'${TMPHOME}'"'
	stub temp_del "${TMPHOME}"
	stub fail
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	unset -f temp_make
	unset -f temp_del
	unset -f fail
	function setup()
	{
		echo "Before: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}" >>${OUTPUT}
		scoped_blank_home
	}
	function teardown()
	{
		fire_teardown_fns
		echo "After: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}" >>${OUTPUT}
	}
	@test "test" {
		echo "During: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}" >>${OUTPUT}
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_success
	run cat $OUTPUT
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME=" \
					 "During: HOME=${TMPHOME} _ORIG_HOME=${HOME}" \
					 "After: HOME=${HOME} _ORIG_HOME=${HOME}"
	unstub temp_make
	unstub temp_del
	unstub fail
}

@test "$PROG: teardown blank \$HOME only after setup" {
	source "${DF_TESTS}/utils.sh"
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	@test "test" {
		exec >>${OUTPUT}
		exec 2>>${OUTPUT}
		unset -f temp_make
		unset -f temp_del
		unset -f fail
		teardown_blank_home
		echo "After: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
	}
	EOF

	stub fail '* : false'
	run bats -t "${TESTFILE}"
	assert_failure
	run cat $OUTPUT
	assert_all_lines
	unstub fail
}
