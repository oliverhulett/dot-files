#!/usr/bin/env bats

PROG="alterlimitsdb.sh"

DF_TESTS="$(dirname "$(cd "${BATS_TEST_DIRNAME}" && pwd -P)")"
source "${DF_TESTS}/utils.sh"

eval "${save_setup}"
function setup()
{
	saved_setup
	ORIG_DB_URI="postgresql://operat@deven002:6002/limitsdb_ml"
}

eval "${save_teardown}"
function teardown()
{
	unstub clone.sh
	unstub get-repo-dir.sh
	unstub python26
	saved_teardown
}

@test "$PROG: clones limits_server if no \$ALTERLIMITSDB_DIR" {
	stub clone.sh "limits_system limits_server"
	stub get-repo-dir.sh "limits_system limits_server alterlimitsdb : echo $BATS_TMPDIR"
	stub python26 "-m Server.DataModel.alterlimitsdb --db=$ORIG_DB_URI arg1 arg2"
	assert [ -d "$BATS_TMPDIR" ]
	run $PROG arg1 arg2
	assert_success
}

@test "$PROG: uses given \$ALTERLIMITSDB_DIR" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26 "-m Server.DataModel.alterlimitsdb --db=$ORIG_DB_URI arg1 arg2"
	export ALTERLIMITSDB_DIR="$BATS_TMPDIR"
	assert [ -n "$ALTERLIMITSDB_DIR" ] && [ -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_success
}

@test "$PROG: fails if \$ALTERLIMITSDB_DIR doesn't exist" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26 "-m Server.DataModel.alterlimitsdb --db=$ORIG_DB_URI arg1 arg2"
	export ALTERLIMITSDB_DIR="/dev/null"
	assert [ ! -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_failure
}

@test "$PROG: uses given \$DB_URI" {
	stub clone.sh
	stub get-repo-dir.sh
	stub python26 "-m Server.DataModel.alterlimitsdb --db=another_uri arg1 arg2"
	export DB_URI="another_uri"
	export ALTERLIMITSDB_DIR="$BATS_TMPDIR"
	assert [ -n "$ALTERLIMITSDB_DIR" ] && [ -d "$ALTERLIMITSDB_DIR" ]
	run $PROG arg1 arg2
	assert_success
}
