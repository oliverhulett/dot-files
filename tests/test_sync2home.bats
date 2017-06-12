#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

FUT="sync2home.sh"

function md5()
{
	md5sum "$@" | cut -d' ' -f1
}

function setup()
{
	assert_fut_exe
	scoped_mktemp BARE_REPO_1 -d
	scoped_mktemp BARE_REPO_2 -d
	scoped_mktemp CHECKOUT_1 -d
	scoped_mktemp CHECKOUT_2 -d
	# Create two "bare" repos
	( cd "${BARE_REPO_1}" && git init --bare )
	( cd "${BARE_REPO_2}" && git init --bare )
	# Clone each repo
	( cd "${CHECKOUT_1}" && git clone "${BARE_REPO_1}" repo1 )
	( cd "${CHECKOUT_2}" && git clone "${BARE_REPO_2}" repo2 )
	# Cross link the repos
	( cd "${CHECKOUT_1}/repo1" && git remote add other "${BARE_REPO_2}" )
	( cd "${CHECKOUT_2}/repo2" && git remote add other "${BARE_REPO_1}" )

	IGNORE_LIST=( "not-synced.txt" "file1.txt" "file2.txt" )
	printf "%s\n" "${IGNORE_LIST[@]}" >"${CHECKOUT_1}/repo1/sync2home.ignore.txt"
	printf "%s\n" "${IGNORE_LIST[@]}" >"${CHECKOUT_2}/repo2/sync2home.ignore.txt"
	cp "${EXE}" "${CHECKOUT_1}/repo1/"
	cp "${EXE}" "${CHECKOUT_2}/repo2/"

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo "text 1" >file1.txt
	echo "same text" >shared-file.txt
	echo "conflict 1" >not-synced.txt
	git add -A >/dev/null 2>/dev/null
	git commit -m"Initial commit on repo 1" >/dev/null 2>/dev/null
	git push >/dev/null 2>/dev/null

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo "text 2" >file2.txt
	echo "same text" >shared-file.txt
	echo "conflict 2" >not-synced.txt
	git add -A >/dev/null 2>/dev/null
	git commit -m"Initial commit on repo 2" >/dev/null 2>/dev/null
	git push >/dev/null 2>/dev/null

	SYNC2HOME_SH_MD5="$(md5 "${EXE}")"
}

function assert_files()
{
	cd "$1" || fail "Failed to change into directory: $1"
	shift
	run ls -1 --color=never
	assert_all_lines $(printf "%s\n" "sync2home.sh" "sync2home.ignore.txt" "shared-file.txt" "not-synced.txt" "$@" | sort -u)
	assert_equal "$(md5 "${CHECKOUT_1}/repo1/sync2home.sh")" "${SYNC2HOME_SH_MD5}"
	assert_equal "$(md5 "${CHECKOUT_2}/repo2/sync2home.sh")" "${SYNC2HOME_SH_MD5}"
	assert_equal "$(cat "${CHECKOUT_1}/repo1/sync2home.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
	assert_equal "$(cat "${CHECKOUT_2}/repo2/sync2home.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
}

function assert_contents()
{
	run cat "$1"
	shift
	assert_all_lines "$@"
}

function assert_checkout_clean()
{
	cd "$1" || fail "Failed to change into directory: $1"
	shift
	run git status -s
	assert_output ""
}

@test "$FUT: fail if no other remotes" {
	scoped_mktemp CHECKOUT -d
	( cd "${CHECKOUT}" && git clone "${BARE_REPO_1}" repo )
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	run s2h
	assert_failure
	assert_checkout_clean "${CHECKOUT}/repo"
}
# fail? if more than one other remote

@test "$FUT: fail if working copy is not clean" {
	skip "Stub version doesn't check"
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "new file" >new-file.txt

	run s2h
	assert_failure

	rm new-file.txt
	echo "addition" >>file1.txt

	run s2h
	assert_failure
}

@test "$FUT: adding a file" {
	cd "${CHECKOUT_1}/repo1" || fail "Faled to change in directory: ${CHECKOUT_1}/repo1"
	echo "new file" >new-file.txt
	git add new-file.txt
	git commit -m"New file"

	run s2h
	assert_success
	assert_checkout_clean "${CHECKOUT_1}/repo1"
	assert_files "${CHECKOUT_1}/repo1" file1.txt new-file.txt
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Faled to change in directory: ${CHECKOUT_2}/repo2"

	run s2h
	assert_success
	assert_checkout_clean "${CHECKOUT_2}/repo2"
	assert_files "${CHECKOUT_2}/repo2" file2.txt new-file.txt
	git push

	run s2h
	assert_success
	assert_checkout_clean "${CHECKOUT_2}/repo2"
	assert_files "${CHECKOUT_2}/repo2" file2.txt new-file.txt
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Faled to change in directory: ${CHECKOUT_1}/repo1"
	run s2h
	assert_success
	assert_checkout_clean "${CHECKOUT_1}/repo1"
	assert_files "${CHECKOUT_1}/repo1" file1.txt new-file.txt
	git push
}

@test "$FUT: adding a conflicting file" {
	cd "${CHECKOUT_1}/repo1" || fail "Faled to change in directory: ${CHECKOUT_1}/repo1"
	echo "new file 1" >new-file.txt
	git add new-file.txt
	git commit -m"New file"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Faled to change in directory: ${CHECKOUT_2}/repo2"
	echo "new file 1" >new-file.txt
	git add new-file.txt
	git commit -m"New file"
	git push

	run s2h
	assert_success
	assert_checkout_clean "${CHECKOUT_2}/repo2"
	assert_files "${CHECKOUT_2}/repo2" file2.txt new-file.txt

	echo "addition" >>new-file.txt
	git commit -am"addition"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Faled to change in directory: ${CHECKOUT_1}/repo1"
	echo "conflict" >>new-file.txt
	git commit -am"conflict"
	git push

	run s2h
	assert_success
	! assert_checkout_clean "${CHECKOUT_1}/repo1"

	assert_files "${CHECKOUT_1}/repo1" file1.txt new-file.txt
	assert_files "${CHECKOUT_2}/repo2" file2.txt new-file.txt
}

# adding ignored file locally
# adding ignored file remotely
# adding ignored file both
# changing existing file locally
# changing existing file remotely
# changing ignored file locally
# changing ignored file remotely
# changing existing file both (same change)
# changing existing file both (conflicting change)
# changing existing file both (non-conflicting change)
# deleting file locally
# deleting file remotely
# deleting file both
# deleting ignored file locally
# deleting ignored file remotely
# deleting ignored file both

function s2h()
{
	set -e
	echo
	echo "SYNCHING: `pwd`"
	echo
	set -x
	git pull --all
	git fetch other master
	git merge --allow-unrelated-histories --no-ff --no-commit FETCH_HEAD || true
	git reset -- $(cat sync2home.ignore.txt)
	git checkout --ours --ignore-skip-worktree-bits -- $( (cat sync2home.ignore.txt; git ls-files) | sort | uniq -d )
	git clean -fd
	git status
	git commit --allow-empty -am"Synching from other at `pwd`"
	set +x
}
