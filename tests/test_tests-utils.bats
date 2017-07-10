#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"

FUT="tests/utils.sh"

function setup()
{
	source "${DF_TESTS}/utils.sh"
	assert_fut
	unset _TEARDOWN_FNS
	unset _ORIG_HOME
}

_assert_all_lines_test_cnt=1
function _do_assert_all_lines_test()
{
	expected_errors=$1
	shift
	local output
	set +e; output="$(assert_all_lines "$@" 2>&1)"; retval=$?; set -e
	assert_equal $retval "$expected_errors" || echo -e "Failed expectation #${_assert_all_lines_test_cnt}:  Test args: $*\n${output}" | fail
	_assert_all_lines_test_cnt=$((_assert_all_lines_test_cnt + 1))
}
@test "$FUT: assert_all_lines" {
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

@test "$FUT: register teardown functions" {
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

function _scoped_environment_inspect_env()
{
	env | command grep -E "^$1="
}
@test "$FUT: scoped environment" {
	export THING2="things"
	run _scoped_environment_inspect_env THING1
	assert_output ""
	run _scoped_environment_inspect_env THING2
	assert_output "THING2=things"

	scoped_env THING1="words" THING2
	run _scoped_environment_inspect_env THING1
	assert_output "THING1=words"
	run _scoped_environment_inspect_env THING2
	assert_output "THING2=things"

	THING2="other things"
	run _scoped_environment_inspect_env THING1
	assert_output "THING1=words"
	run _scoped_environment_inspect_env THING2
	assert_output "THING2=other things"

	THING1="more words"
	run _scoped_environment_inspect_env THING1
	assert_output "THING1=more words"
	run _scoped_environment_inspect_env THING2
	assert_output "THING2=other things"

	teardown

	run _scoped_environment_inspect_env THING1
	assert_output ""
	run _scoped_environment_inspect_env THING2
	assert_output "THING2=things"
}

@test "$FUT: scoped temporary files and directories are removed on teardown" {
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

function _should_run_mk_test()
{
	unset ONLY SKIP
	rm "${OUTPUT}" || true
	cat - >"${TESTFILE}" <<-EOF
		. "${DF_TESTS}/utils.sh"
		eval "__original_\$(declare -f skip)"
		function skip()
		{
			echo "Skipping='\$*' ONLY=\$ONLY SKIP=\$SKIP" >>"${OUTPUT}"
			__original_skip "should_run said no"
			return 1
		}
		function setup()
		{
			should_run
		}
		ONLY=$1
		SKIP=$2
		@test "test 1" {
			true
		}
		@test "test 2" {
			true
		}
	EOF
}
@test "$FUT: skip tests on request" {
	scoped_mktemp TESTFILE --suffix=.bats
	scoped_mktemp OUTPUT --suffix=.txt
	_should_run_mk_test "" ""
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..2" "ok 1 test 1" "ok 2 test 2"

	_should_run_mk_test '"test 2"' ""
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..2" "ok 1 # skip (should_run said no) test 1" "ok 2 test 2"
	run cat "${OUTPUT}"
	assert_all_lines --partial "Skipping='Single test requested: test 2'"

	_should_run_mk_test "" '( "test 1" "test 2" )'
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..2" "ok 1 # skip (should_run said no) test 1" "ok 2 # skip (should_run said no) test 2"
	run cat "${OUTPUT}"
	assert_all_lines --partial "Skipping='Skip requested by skip list: test 1'" "Skipping='Skip requested by skip list: test 2'"
}

function _assert_fut_exe_mk_test()
{
	unset EXE FUT
	cat - >"${TESTFILE}" <<-EOF
		. "${DF_TESTS}/utils.sh"
		FUT="$1"
		function setup()
		{
			:
		}
		eval "__original_\$(declare -f skip)"
		function skip()
		{
			echo "Skipping='\$*' FUT=\$FUT EXE=\$EXE" >"${OUTPUT}"
			__original_skip "assert_fut_exe failed"
			return 1
		}
		@test "test" {
			assert_fut_exe
			assert [ "\$EXE" == "$2" ]
		}
	EOF
}
@test "$FUT: assert program exists" {
	scoped_mktemp TESTFILE --suffix=.bats
	scoped_mktemp OUTPUT --suffix=.txt
	_assert_fut_exe_mk_test "" ""
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 test"

	_assert_fut_exe_mk_test "none" ""
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 # skip (assert_fut_exe failed) test"
	run cat "${OUTPUT}"
	assert_all_lines --partial "Skipping='Failed to find file under test'"

	_assert_fut_exe_mk_test "tests/data/executable.sh" "${DF_TESTS}/data/executable.sh"
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 test"

	_assert_fut_exe_mk_test "tests/data/shebang.sh" "/bin/bash -asdf ${DF_TESTS}/data/shebang.sh"
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 test"

	_assert_fut_exe_mk_test "tests/data/no-shebang.sh" ""
	run bats -t "${TESTFILE}"
	assert_success
	assert_all_lines "1..1" "ok 1 # skip (assert_fut_exe failed) test"
	run cat "${OUTPUT}"
	assert_all_lines --partial "Skipping='Program under test is not executable or has an invalid shebang'"
}

@test "$FUT: simple test file" {
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	cat - >"${TESTFILE}" <<-EOF
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
	run cat "$OUTPUT"
	assert_all_lines "setup world" \
					 "hello world" \
					 "registered teardown world" \
					 "teardown world"
}

@test "$FUT: setup and teardown inheritance" {
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp DIR -d
	mkdir --parents "${DIR}/tests/dir"
	cat - >"${DIR}/tests/dir/fixture.sh" <<-EOF
		source "${DF_TESTS}/utils.sh"
		DF_TESTS=${DIR}/tests
		function setup_dir()
		{
			echo "setup dir/fixture.sh" >>${OUTPUT}
		}
		function teardown_dir()
		{
			echo "teardown dir/fixture.sh" >>${OUTPUT}
		}
	EOF
	cat - >"${DIR}/tests/dir/file1.bats" <<-EOF
		source "${DIR}/tests/dir/fixture.sh"
		function setup_file1()
		{
			echo "setup dir/file1.bats" >>${OUTPUT}
		}
		function teardown_file1()
		{
			echo "teardown dir/file1.bats" >>${OUTPUT}
		}
		@test "test" {
			echo "\$PATH" >>${OUTPUT}
			echo "hello world" >>${OUTPUT}
		}
	EOF
	run bats -t "${DIR}/tests/dir/file1.bats"
	assert_success
	run cat "$OUTPUT"
	assert_all_lines "setup dir/fixture.sh" \
					 "setup dir/file1.bats" \
					 "--regexp ^${BATS_MOCK_BINDIR}:${DOTFILES}/bin:" \
					 "hello world" \
					 "teardown dir/file1.bats" \
					 "teardown dir/fixture.sh"

	cat - >"${DIR}/tests/dir/file2.bats" <<-EOF
		source "${DIR}/tests/dir/fixture.sh"
		function setup_more()
		{
			:
		}
		function teardown_more()
		{
			:
		}
		@test "test" {
			fail "Warning output is only available if the test fails"
		}
	EOF
	run bats -t "${DIR}/tests/dir/file2.bats"
	assert_failure
	assert_line --index 0 "1..1"
	assert_line --index 1 "not ok 1 test"
	assert_line --index $(( ${#lines[@]} - 3 )) "# WARN: Function \`setup_more' looks like a setup function, but was not found by the setup/teardown inheritance algorithm.  Possible typo?"
	assert_line --index $(( ${#lines[@]} - 2 )) "# Warning output is only available if the test fails"
	assert_line --index $(( ${#lines[@]} - 1 )) "# WARN: Function \`teardown_more' looks like a teardown function, but was not found by the setup/teardown inheritance algorithm.  Possible typo?"
}

@test "$FUT: blank \$HOME" {
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	TMPHOME="$(mktemp -p "${BATS_TMPDIR}" --suffix=home --dry-run "${BATS_TEST_NAME}".XXXXXXXX)"
	cat - >"${TESTFILE}" <<-EOF
		. "${DF_TESTS}/utils.sh"
		function setup()
		{
			:
		}
		@test "test" {
			rm ${OUTPUT} || true
			exec >>${OUTPUT}
			exec 2>>${OUTPUT}
			unset -f temp_make
			unset -f temp_del
			unset -f fail
			echo "Before: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
			new_blank_home
			echo "During: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
			destroy_blank_home
			echo "After: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
		}
	EOF

	stub temp_make '--prefix=home : echo "'"${TMPHOME}"'"'
	stub temp_del "${TMPHOME}"
	stub fail
	run bats -t "${TESTFILE}"
	assert_success
	run cat "$OUTPUT"
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME=" \
					 "During: HOME=${TMPHOME} _ORIG_HOME=${HOME}" \
					 "After: HOME=${HOME} _ORIG_HOME=${HOME}"
	unstub temp_make
	unstub temp_del
	unstub fail

	stub temp_make '--prefix=home : echo "'"${HOME}${TMPHOME}"'"'
	stub temp_del "${HOME}${TMPHOME}"
	stub fail
	run bats -t "${TESTFILE}"
	assert_success
	run cat "$OUTPUT"
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
	run cat "$OUTPUT"
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME="
	unstub temp_make
	unstub temp_del
	unstub fail

	stub temp_make '--prefix=home : echo "'"${HOME}"'"'
	stub temp_del
	stub fail '* : false'
	run bats -t "${TESTFILE}"
	assert_failure
	run cat "$OUTPUT"
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME="
	unstub temp_make
	unstub temp_del
	unstub fail
}

@test "$FUT: scoped blank \$HOME" {
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	TMPHOME="$(mktemp -p "${BATS_TMPDIR}" --suffix=home --dry-run "${BATS_TEST_NAME}".XXXXXXXX)"
	stub temp_make '--prefix=home : echo "'"${TMPHOME}"'"'
	stub temp_del "${TMPHOME}"
	stub fail
	cat - >"${TESTFILE}" <<-EOF
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
	run cat "$OUTPUT"
	assert_all_lines "Before: HOME=${HOME} _ORIG_HOME=" \
					 "During: HOME=${TMPHOME} _ORIG_HOME=${HOME}" \
					 "After: HOME=${HOME} _ORIG_HOME=${HOME}"
	unstub temp_make
	unstub temp_del
	unstub fail
}

@test "$FUT: teardown blank \$HOME only after setup" {
	scoped_mktemp OUTPUT --suffix=.txt
	scoped_mktemp TESTFILE --suffix=.bats
	cat - >"${TESTFILE}" <<-EOF
		. "${DF_TESTS}/utils.sh"
		function setup()
		{
			:
		}
		@test "test" {
			exec >>${OUTPUT}
			exec 2>>${OUTPUT}
			unset -f temp_make
			unset -f temp_del
			unset -f fail
			destroy_blank_home
			echo "After: HOME=\${HOME} _ORIG_HOME=\${_ORIG_HOME}"
		}
	EOF

	stub fail '* : false'
	run bats -t "${TESTFILE}"
	assert_failure
	run cat "$OUTPUT"
	assert_all_lines
	unstub fail
}

@test "$FUT: populate blank \$HOME" {
	run populate_home
	assert_failure

	scoped_blank_home

	run populate_home
	assert_success
	assert_equal "$(find "${HOME}" -type l | sed -re "s:^${HOME}/?::" | sort)" "$(cut -d' ' -f2 "${DOTFILES}/dot-files-common" | sort)"
	EXPECTED_FILES=(
		".dotlogs/$(date '+%Y%m%d')_${USER}_dot-files.log"
		".gitconfig.local"
	)
	assert_equal "$(find "${HOME}" -type f | sed -re "s:^${HOME}/?::" | sort)" "$(printf "%s\n" "${EXPECTED_FILES[@]}" | sort)"
	while read -r SRC LINK; do
		assert test -L "${HOME}/${LINK}"
		assert_equal "$(readlink -f "${HOME}/${LINK}")" "${DOTFILES}/${SRC}"
	done <"${DOTFILES}/dot-files-common"
	refute test -z "$(git config --get user.name)"
	refute test -z "$(git config --get user.email)"
}

function assert_array_eq()
{
	arr_name="$1"
	shift
	assert_equal "$(eval "echo \${#${arr_name}[@]}")" $#
	i=0
	for v in "$@"; do
		assert_equal "$(eval "echo \${${arr_name}[$i]}")" "$v"
		i=$((i + 1))
	done
}
@test "$FUT: _set and _restore" {
	set +b
	set -m
	orig="$-"
	refute grep -q b <(echo $orig)
	assert grep -q m <(echo $orig)

	_set -b
	assert_array_eq _SET_LIST b
	assert grep -q b <(echo $-)
	_restore b
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"

	_set +m
	assert_array_eq _SET_LIST m
	refute grep -q m <(echo $-)
	_restore m
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"

	_set -bm
	assert_array_eq _SET_LIST b m
	assert grep -q b <(echo $-)
	assert grep -q m <(echo $-)
	_restore bm
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"

	_set +bm
	assert_array_eq _SET_LIST b m
	refute grep -q b <(echo $-)
	refute grep -q m <(echo $-)
	_restore b
	assert_array_eq _SET_LIST m
	refute grep -q b <(echo $-)
	refute grep -q m <(echo $-)
	_restore m
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"

	_set -b +m
	assert_array_eq _SET_LIST b m
	assert grep -q b <(echo $-)
	refute grep -q m <(echo $-)
	_restore m b
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"

	_set -m +b
	assert_array_eq _SET_LIST m b
	refute grep -q b <(echo $-)
	assert grep -q m <(echo $-)
	_restore_all
	assert_array_eq _SET_LIST
	assert_equal "$-" "${orig}"
}
