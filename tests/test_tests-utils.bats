#!/usr/bin/env bats

PROG="utils.sh"

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"

#@test "$PROG: register setup functions" {
#	source "${DF_TESTS}/utils.sh"
#	run setup
#	assert_success
#	assert_output ""
#
#	register_setup_fn echo this
#	run setup
#	assert_success
#	assert_output "this"
#
#	register_setup_fn echo that
#	run setup
#	assert_success
#	assert_line --index 0 "this"
#	assert_line --index 1 "that"
#}
#
#@test "$PROG: register teardown functions" {
#	source "${DF_TESTS}/utils.sh"
#	run teardown
#	assert_success
#	assert_output ""
#
#	register_teardown_fn echo this
#	run teardown
#	assert_success
#	assert_output "this"
#
#	register_teardown_fn echo that
#	run teardown
#	assert_success
#	assert_line --index 0 "this"
#	assert_line --index 1 "that"
#}

@test "$PROG: multiple includes" {
	source "${DF_TESTS}/utils.sh"
	OUTPUT="$(mktemp -p "${BATS_TMPDIR}" --suffix=.txt ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $OUTPUT
	TESTHELPER="$(mktemp -p "${BATS_TMPDIR}" --suffix=.sh ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTHELPER
	cat >"${TESTHELPER}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	function asdf()
	{
		echo "sourced stdout"
		echo "sourced stderr" >&2
		echo "sourced file" >>${OUTPUT}
	}
	register_setup_fn asdf
	EOF
	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
	register_teardown_fn rm $TESTFILE
	cat >"${TESTFILE}" <<-EOF
	. "${DF_TESTS}/utils.sh"
	source "${TESTHELPER}"
	function asdf()
	{
		echo "setup stdout"
		echo "setup stderr" >&2
		echo "setup file" >>${OUTPUT}
	}
	set -x
	register_setup_fn asdf
	register_setup_fn echo this
	set +x
	@test "test" {
		echo "hello stdout"
		echo "hello stderr" >&2
		echo "hello file" >>${OUTPUT}
	}
	EOF
	run bats -t "${TESTFILE}"
	assert_output ""
	run cat $TESTFILE
	assert_output ""
}

#@test "$PROG: blank \$HOME" {
#	TESTFILE="$(mktemp -p "${BATS_TMPDIR}" --suffix=.bats ${BATS_TEST_NAME}.XXXXXXXX)"
#	register_teardown_fn rm $TESTFILE
#	cat >"${TESTFILE}" <<-EOF
#	source "${DF_TESTS}/utils.sh"
#	source "${TESTHELPER}"
#	function _setup()
#	{
#		echo "setup stdout"
#		echo "setup stderr" >&2
#		echo "setup file" >>${OUTPUT}
#	}
#	register_setup_fn _setup
#	@test "test" {
#		echo "hello stdout"
#		echo "hello stderr" >&2
#		echo "hello file" >>${OUTPUT}
#		fail "goodbye world"
#	}
#	EOF
#	run bats -t "${TESTFILE}"
#}
