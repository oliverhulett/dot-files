#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="bin/colourise.py"

COLOUR_PATTERN="$(printf '\033\[.;..m')"
RESET="$(printf '\033\[0m')"
COLOUR1="$(printf '\033\[1;34m')"
COLOUR2="$(printf '\033\[1;32m')"

@test "$PROG: will colourise stdin" {
	run $EXE <<-EOF
		Line should not be colourised
		10:11:12.123456789 [module1] Default regex should pick colour1
		10:11:12.123456789 [module2] Default regex should pick colour2
	EOF
	assert_success
	assert_all_lines "Colourising stdin..." \
					 "Line should not be colourised" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module2\] Default regex should pick colour2'"${RESET}"
}

@test "$PROG: uses first line to detect logging format.  Optiver C++" {
	run $EXE <<-EOF
		10:11:12.123456789 [LEVEL ] [MODULE1] line one is colourised and picks the C++ pattern
		10:11:13.123456789 [LEVEL1] [MODULE1] line two has the same colour because it is the same module
		10:11:14.123456789 [LEVEL ] [MODULE2] line three has a different colour
		[LEVEL] [MODULE1] line four is not coloured because it doesn't match the regex
		2017-05-04 10:11:15.123456789 [LEVEL ] [MODULE1] Can have a date at the front
		10:11:16.123456789 [ 10 ms] [LEVEL ] [MODULE1] Can have a latency measure
		10:11:17.123456789 [LEVEL ] [MODULE2] [MODULE1] Can have other segments
	EOF
	assert_success
	assert_all_lines "Colourising stdin..." \
					 "--regexp ${COLOUR1}"'10:11:12\.123456789 \[LEVEL \] \[MODULE1\] line one is colourised and picks the C\+\+ pattern'"${RESET}" \
					 "--regexp ${COLOUR1}"'10:11:13\.123456789 \[LEVEL1\] \[MODULE1\] line two has the same colour because it is the same module'"${RESET}" \
					 "--regexp ${COLOUR2}"'10:11:14\.123456789 \[LEVEL \] \[MODULE2\] line three has a different colour'"${RESET}" \
					 "[LEVEL] [MODULE1] line four is not coloured because it doesn't match the regex" \
					 "--regexp ${COLOUR1}"'2017-05-04 10:11:15\.123456789 \[LEVEL \] \[MODULE1\] Can have a date at the front'"${RESET}" \
					 "--regexp ${COLOUR1}"'10:11:16\.123456789 \[ 10 ms\] \[LEVEL \] \[MODULE1\] Can have a latency measure'"${RESET}" \
					 "--regexp ${COLOUR2}"'10:11:17\.123456789 \[LEVEL \] \[MODULE2\] \[MODULE1\] Can have other segments'"${RESET}"
}

@test "$PROG: uses first line to detect logging format.  Optiver Python" {
	run $EXE <<-EOF
		2017-05-04 10:11:12 [LEVEL ] module1:classname: line one is colourised and picks the Python pattern
		2017-05-04 10:11:13 [LEVEL1] module1:classname: line two has the same colour because it is the same module
		2017-05-04 10:11:14 [LEVEL ] module2:classname: line three has a different colour
		[LEVEL] module1:classname: line four is not coloured because it doesn't match the regex
		10:11:15 [LEVEL ] module1:classname: Must have a date at the front
		2017-05-04 10:11:17 [LEVEL ] module2:module1:classname: Can have other segments
		2017-05-04 10:11:17.123456789 [LEVEL ] module1:classname: Can have nanoseconds
		2017-05-04 10:11:17,123 [LEVEL ] module1:classname: Can have milliseconds
	EOF
	assert_success
	assert_all_lines "Colourising stdin..." \
					 "--regexp ${COLOUR1}"'2017-05-04 10:11:12 \[LEVEL \] module1:classname: line one is colourised and picks the Python pattern'"${RESET}" \
					 "--regexp ${COLOUR1}"'2017-05-04 10:11:13 \[LEVEL1\] module1:classname: line two has the same colour because it is the same module'"${RESET}" \
					 "--regexp ${COLOUR2}"'2017-05-04 10:11:14 \[LEVEL \] module2:classname: line three has a different colour'"${RESET}" \
					 "[LEVEL] module1:classname: line four is not coloured because it doesn't match the regex" \
					 "10:11:15 [LEVEL ] module1:classname: Must have a date at the front" \
					 "--regexp ${COLOUR2}"'2017-05-04 10:11:17 \[LEVEL \] module2:module1:classname: Can have other segments'"${RESET}" \
					 "--regexp ${COLOUR1}"'2017-05-04 10:11:17\.123456789 \[LEVEL \] module1:classname: Can have nanoseconds'"${RESET}" \
					 "--regexp ${COLOUR1}"'2017-05-04 10:11:17,123 \[LEVEL \] module1:classname: Can have milliseconds'"${RESET}"
}

@test "$PROG: will colourise a given file" {
	scoped_mktemp TESTFILE --suffix=.log
	cat >"${TESTFILE}" <<-EOF
		Line should not be colourised
		10:11:12.123456789 [module1] Default regex should pick colour1
		10:11:12.123456789 [module2] Default regex should pick colour2
	EOF
	run $EXE "${TESTFILE}"
	assert_success
	assert_all_lines "Colourising ${TESTFILE}..." \
					 "Line should not be colourised" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module2\] Default regex should pick colour2'"${RESET}"
}

@test "$PROG: will colourise multiple given files" {
	scoped_mktemp TESTFILE1 --suffix=.log
	cat >"${TESTFILE1}" <<-EOF
		Line should not be colourised
		10:11:12.123456789 [module1] Default regex should pick colour1
		10:11:12.123456789 [module2] Default regex should pick colour2
	EOF
	scoped_mktemp TESTFILE2 --suffix=.log
	cat >"${TESTFILE2}" <<-EOF
		Line should not be colourised
		11:10.13.123456789 [module1] Default regex should pick colour1
		11:10.13.123456789 [module2] Default regex should pick colour2
	EOF
	run $EXE "${TESTFILE1}" "${TESTFILE2}"
	assert_success
	assert_all_lines "Colourising ${TESTFILE1}..." \
					 "Line should not be colourised" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module2\] Default regex should pick colour2'"${RESET}" \
					 "Colourising ${TESTFILE2}..." \
					 "Line should not be colourised" \
					 "--regexp ${COLOUR_PATTERN}"'11:10\.13.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'11:10\.13.123456789 \[module2\] Default regex should pick colour2'"${RESET}"
}

@test "$PROG: first arg can be a pattern" {
	run $EXE '.+colour([a-zA-Z0-9]+)$' <<-EOF
		Line should be colourised
		10:11:12.123456789 [module1] Default regex should pick colour1
		10:11:12.123456789 [module2] Default regex should pick colour2
		No colours if the regex doesn't match
	EOF
	assert_success
	assert_all_lines "Colourising stdin..." \
					 "--regexp ${COLOUR_PATTERN}"'Line should be colourised'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module2\] Default regex should pick colour2'"${RESET}" \
					 "No colours if the regex doesn't match"
}

@test "$PROG: if first arg is a pattern then still accepts file args" {
	scoped_mktemp TESTFILE --suffix=.log
	cat >"${TESTFILE}" <<-EOF
		Line should be colourised
		10:11:12.123456789 [module1] Default regex should pick colour1
		10:11:12.123456789 [module2] Default regex should pick colour2
		No colours if the regex doesn't match
	EOF
	run $EXE '.+colour([a-zA-Z0-9]+)$' "${TESTFILE}"
	assert_success
	assert_all_lines "Colourising ${TESTFILE}..." \
					 "--regexp ${COLOUR_PATTERN}"'Line should be colourised'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module1\] Default regex should pick colour1'"${RESET}" \
					 "--regexp ${COLOUR_PATTERN}"'10:11:12\.123456789 \[module2\] Default regex should pick colour2'"${RESET}" \
					 "No colours if the regex doesn't match"
}
