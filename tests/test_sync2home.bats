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

@test "$FUT: initial commits and merges" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo "text 1" >file1.txt
	echo "same text" >shared-file.txt
	echo "confict 1" >not-synced.txt
	run git add -A
	run git commit -m"Added file1"
	run git push
	echo
	git lg
	echo
	git status
	echo ONE one
	pwd
	ls -l
	cat *

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo "text 2" >file2.txt
	echo "same text" >shared-file.txt
	echo "confict 2" >not-synced.txt
	run git add -A
	run git commit -m"Added file2"
	run git push
	echo
	git lg
	echo
	git pull
	echo
	git fetch other master
	echo
	git merge --no-ff --no-commit FETCH_HEAD || true
	echo
	git reset -- not-synced.txt file1.txt file2.txt
	echo
	git checkout --ours --ignore-skip-worktree-bits -- $( (echo -e 'not-synced.txt\nfile1.txt\nfile2.txt'; git ls-files) | sort | uniq -d)
	echo
	git clean -fd
	echo
	git status
	echo
	git commit --allow-empty -am"sync r1 -> r2"
	git lg
	echo
	git push
	echo
	git status
	echo TWO one
	pwd
	ls -l
	cat *

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo
	git lg
	echo
	git pull
	echo
	git fetch other master
	echo
	git merge --no-ff --no-commit FETCH_HEAD || true
	echo
	git reset -- not-synced.txt file1.txt file2.txt
	echo
	git checkout --ours --ignore-skip-worktree-bits -- $( (echo -e 'not-synced.txt\nfile1.txt\nfile2.txt'; git ls-files) | sort | uniq -d)
	echo
	git clean -fd
	echo
	git status
	echo
	git commit --allow-empty -am"sync r2 -> r1"
	echo
	git lg
	echo
	git push
	echo
	git status
	echo ONE two
	pwd
	ls -l
	cat *

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo
	git lg
	echo
	git pull
	echo
	git fetch other master
	echo
	git merge --no-ff --no-commit FETCH_HEAD || true
	echo
	git reset -- not-synced.txt file1.txt file2.txt
	echo
	git checkout --ours --ignore-skip-worktree-bits -- $( (echo -e 'not-synced.txt\nfile1.txt\nfile2.txt'; git ls-files) | sort | uniq -d)
	echo
	git clean -fd
	echo
	git status
	echo
	git commit --allow-empty -am"sync r1 -> r2 again"
	echo
	git lg
	echo
	git status
	echo TWO two
	pwd
	ls -l
	cat *

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo
	git lg
	echo
	git pull
	echo
	git fetch other master
	echo
	git merge --no-ff --no-commit FETCH_HEAD || true
	echo
	git reset -- not-synced.txt file1.txt file2.txt
	echo
	git checkout --ours --ignore-skip-worktree-bits -- $( (echo -e 'not-synced.txt\nfile1.txt\nfile2.txt'; git ls-files) | sort | uniq -d)
	echo
	git clean -fd
	echo
	git status
	echo
	git commit --allow-empty -am"sync r2 -> r1 again"
	echo
	git lg
	echo
	git status
	echo ONE three
	pwd
	ls -l
	cat *

	fail "test"
}
