#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

TEST_FILE="sync2home.sh"

function md5()
{
	md5sum "$1" | cut -d' ' -f1
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
	git add -A
	git commit -m"Initial commit on repo 1"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo "text 2" >file2.txt
	echo "same text" >shared-file.txt
	echo "conflict 2" >not-synced.txt
	git add -A
	git commit -m"Initial commit on repo 2"
	git push

	SYNC2HOME_SH_MD5="$(md5 "${EXE}")"
}

## assertions
# file lists (sort)
# file contents
# no un-committed files
# git logs?  Find commits from other remote?
function assert_files()
{
	run ls -1 --color=never
	assert_lines $(printf "%s\n" "sync2home.sh" "sync2home.ignore.txt" "shared-file.txt" "$@" | sort)
	assert_equals "$(md5 "${CHECKOUT_1}/repo1/sync2home.sh")" "${SYNC2HOME_SH_MD5}"
	assert_equals "$(md5 "${CHECKOUT_2}/repo2/sync2home.sh")" "${SYNC2HOME_SH_MD5}"
	assert_equals "$(cat "${CHECKOUT_1}/repo1/sync2home.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
	assert_equals "$(cat "${CHECKOUT_2}/repo2/sync2home.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
}


function s2h()
{
	SKIP_LIST="not-synced.txt\nfile1.txt\nfile2.txt"

	echo
	echo "SYNCHING"
	echo "$*"
	echo
	git push
	git pull
	git fetch other master
	git merge --allow-unrelated-histories --no-ff --no-commit FETCH_HEAD || true
	git reset -- $(echo -e "$SKIP_LIST")
	git checkout --ours --ignore-skip-worktree-bits -- $( (echo -e "$SKIP_LIST"; git ls-files) | sort | uniq -d )
	git clean -fd
	git status
	git commit --allow-empty -am"$*"
}

## Tests to write
# fail if no other remote
# fail? if more than one other remote
# adding a file locally
# adding a file remotely
# adding the same file both
# adding conflicting file both
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
