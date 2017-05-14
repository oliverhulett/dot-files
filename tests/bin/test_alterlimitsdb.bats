#!/usr/bin/env bats

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

PROG="$(find_prog "alterlimitsdb.sh")"

eval "${save_setup}"
function setup()
{
	if [ -z "$PROG" ]; then
		skip
	fi
	saved_setup
	ORIG_DB_URI="postgresql://operat@devenv002:6002/limitsdb_ml"
	MODULE="Server.DataModel.alterlimitsdb"
}

eval "${save_teardown}"
function teardown()
{
	saved_teardown
}

@test "$PROG: clones limits_server if no \$ALTERLIMITSDB_DIR" {
	stub clone.sh "limits_system limits_server"
	stub get-repo-dir.sh "limits_system limits_server alterlimitsdb : echo $BATS_TMPDIR"
	stub python26 "-m $MODULE --db=$ORIG_DB_URI arg1 arg2"
	assert [ -d "$BATS_TMPDIR" ]
	run $PROG arg1 arg2
	assert_success
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
}

@test "$PROG: uses given \$ALTERLIMITSDB_DIR" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26 "-m $MODULE --db=$ORIG_DB_URI arg1 arg2"
	export ALTERLIMITSDB_DIR="$BATS_TMPDIR"
	assert [ -n "$ALTERLIMITSDB_DIR" ] && [ -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_success
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
}

@test "$PROG: fails if \$ALTERLIMITSDB_DIR doesn't exist" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26
	export ALTERLIMITSDB_DIR="/dev/null"
	assert [ -n "$ALTERLIMITSDB_DIR" ] && [ ! -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_failure
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
}

@test "$PROG: failes if clone fails" {
	stub clone.sh "limits_system limits_server"
	stub get-repo-dir.sh "limits_system limits_server alterlimitsdb"
	stub python26
	run $PROG arg1 arg2
	assert_failure
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
}

@test "$PROG: uses given \$DB_URI" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26 "-m $MODULE --db=another_uri arg1 arg2"
	export DB_URI="another_uri"
	export ALTERLIMITSDB_DIR="$BATS_TMPDIR"
	assert [ -n "$ALTERLIMITSDB_DIR" ] && [ -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_success
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
}
