#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

DOT_FILES="$(dirname "${DF_TESTS}")"
IGNORE_LIST="${DOT_FILES}/sync-other-remote.ignore.txt"

@test "Ignore list file exists" {
	assert test -e "${IGNORE_LIST}"
}

@test "Ignore list is sorted and uniq" {
	assert_equal \
		"$(command cat "${IGNORE_LIST}")" \
		"$(command cat "${IGNORE_LIST}" | sort -u)"
}

@test "All ignored files exist" {
	OTHER_REMOTE="$(cd "${DOT_FILES}" && git remote | command grep -v origin || true)"
	if [ -z "${OTHER_REMOTE}" ]; then
		skip "cannot verify ignored files exist without other remote"
		return
	fi

	scoped_mktemp CHECKOUT -d
	git clone --depth 1 --branch "$(git this)" "$(git config --get "remote.${OTHER_REMOTE}.url")" "${CHECKOUT}"

	shopt nullglob
	while read -r; do
		assert find "${DOT_FILES}" "${CHECKOUT}" -wholename "${REPLY}" -print -quit
	done <"${IGNORE_LIST}"
}
