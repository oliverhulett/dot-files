#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"

PROG="utils.sh"

function setup()
{
	: ## We specifically don't want the common setup(), since our $PROG is not a real program.
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

@test "$PROG: assert program exists" {
	source "${DF_TESTS}/utils.sh"
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
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

@test "$PROG: simple test file" {
	source "${DF_TESTS}/utils.sh"
	OUTPUT="$(mktemp -p "${BATS_TMPDIR}" --suffix=.txt ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $OUTPUT
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
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
	OUTPUT="$(mktemp -p "${BATS_TMPDIR}" --suffix=.txt ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $OUTPUT
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
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
	OUTPUT="$(mktemp -p "${BATS_TMPDIR}" --suffix=.txt ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $OUTPUT
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
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
	OUTPUT="$(mktemp -p "${BATS_TMPDIR}" --suffix=.txt ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $OUTPUT
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
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

@test "$PROG: assert_all_lines" {
	source "${DF_TESTS}/utils.sh"
	run echo -e $' line1\nline 2\nline3 '

	# Note that this pattern is required to get the return value but not fail the test when asser_all_lines is expected
	# to fail.  Unfortunately it screws up the error reporting, so you'll have to manually count the errors and the
	# expected errors to work out what failed.
	set +e; assert_all_lines " line1" "line 2" "line3 "; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines "line1" "line 2" "line3 "; retval=$?; set -e
	assert_equal $retval 1

	set +e; assert_all_lines "line1" "line 2" "line3"; retval=$?; set -e
	assert_equal $retval 2

	set +e; assert_all_lines "line1" "line 2" "line3" ""; retval=$?; set -e
	assert_equal $retval 3

	set +e; assert_all_lines " line1" "line 2" "line3 "; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines "line1" "line 2" "line3 "; retval=$?; set -e
	assert_equal $retval 1

	set +e; assert_all_lines " line1" "line 2" "line3"; retval=$?; set -e
	assert_equal $retval 1

	set +e; assert_all_lines " line1" "line 2"; retval=$?; set -e
	assert_equal $retval 1

	set +e; assert_all_lines " line1" "line 2" "line3 " "line4"; retval=$?; set -e
	assert_equal $retval 2 # "line4" doesn't match empty string and count is wrong.

	set +e; assert_all_lines --regexp "^ line.$" "^li.e 2$" "^li..3 $"; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines --partial "ine" "lin" "ne3"; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines " line1" "--regexp ^line.+$" "--partial ine"; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines "--regexp line1$" "line 2" "line3 "; retval=$?; set -e
	assert_equal $retval 0

	set +e; assert_all_lines " line1" "line 2" " --partial ine"; retval=$?; set -e
	assert_equal $retval 1

	run echo -n
	set +e; assert_all_lines; retval=$?; set -e
	assert_equal $retval 0
}
