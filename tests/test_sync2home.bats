#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

TEST_FILE="sync2home.sh"

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

function status()
{
	echo
	echo "$@"
	echo
	git lg
	echo
	git status
	echo
	pwd
	ls -l
	cat *
	echo
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

## assertions
# file lists (sort)
# file contents
# no un-committed files
# git logs?  Find commits from other remote?

@test "$FUT: initial commits and merges" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo "text 1" >file1.txt
	echo "same text" >shared-file.txt
	echo "confict 1" >not-synced.txt
	git add -A
	git commit -m"Added file1"
	git push
	status ONE one

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo "text 2" >file2.txt
	echo "same text" >shared-file.txt
	echo "confict 2" >not-synced.txt
	git add -A
	git commit -m"Added file2"
	git push
	status TWO one b4
	s2h "sync r1 -> r2 1"
	status TWO one after

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	status ONE two b4
	s2h "sync r2 -> r1 1"
	status ONE two after

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	status TWO two b4
	s2h "sync r1 -> r2 2"
	status TWO two during
	echo "addition" >>shared-file.txt
	echo "conflict" >>not-synced.txt
	git commit -am"Changes at 2"
	git push
	status TWO two after

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	status ONE three b4
	s2h "sync r2 -> r1 2"
	status ONE three during
	s2h "sync r2 -> r1 3"
	status ONE three after

	fail "test"
}
