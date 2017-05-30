#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

TEST_FILE="sync2home.sh"

function setup()
{
	assert_fut_exe
}
