#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

FUT="sync-other-remote.sh"

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
	printf "%s\n" "${IGNORE_LIST[@]}" >"${CHECKOUT_1}/repo1/sync-other-remote.ignore.txt"
	printf "%s\n" "${IGNORE_LIST[@]}" >"${CHECKOUT_2}/repo2/sync-other-remote.ignore.txt"
	cp "${EXE}" "${CHECKOUT_1}/repo1/"
	cp "${EXE}" "${CHECKOUT_2}/repo2/"

	for d in "${CHECKOUT_1}/repo1" "${CHECKOUT_2}/repo2"; do
		cat >"$d/shared-file.txt" <<-EOF
			line one
			some more text

			last line
		EOF
	done
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory for checkout 1"
	echo "text 1" >file1.txt
	echo "conflict 1" >not-synced.txt
	git add -A
	git commit -m"Initial commit on repo 1" >/dev/null 2>/dev/null
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory for checkout 2"
	echo "text 2" >file2.txt
	echo "conflict 2" >not-synced.txt
	git add -A
	git commit -m"Initial commit on repo 2" >/dev/null 2>/dev/null
	git push

	SOR_SH_MD5="$(md5 "${EXE}")"

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	git push
}

function assert_files()
{
	cd "$1" || fail "Failed to change into directory: $1"
	shift
	run ls -1 --color=never
	assert_all_lines $(printf "%s\n" "sync-other-remote.sh" "sync-other-remote.ignore.txt" "$@" | sort -u)
	assert_equal "$(md5 "${CHECKOUT_1}/repo1/sync-other-remote.sh")" "${SOR_SH_MD5}"
	assert_equal "$(md5 "${CHECKOUT_2}/repo2/sync-other-remote.sh")" "${SOR_SH_MD5}"
	assert_equal "$(cat "${CHECKOUT_1}/repo1/sync-other-remote.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
	assert_equal "$(cat "${CHECKOUT_2}/repo2/sync-other-remote.ignore.txt")" "$(printf "%s\n" "${IGNORE_LIST[@]}")"
	cd - || fail "Failed to restore directory"
}

function assert_contents()
{
	run cat "$1"
	shift
	assert_all_lines "$@"
}

function assert_checkout_clean()
{
	run git status -s
	assert_output ""
}

@test "$FUT: fail if there is not exactly one other remote" {
	scoped_mktemp BARE_REPO -d
	scoped_mktemp CHECKOUT -d
	( cd "${BARE_REPO}" && git init --bare )
	( cd "${CHECKOUT}" && git clone "${BARE_REPO}" repo )
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	cp "${EXE}" "${CHECKOUT}/repo/"
	git add -A
	git commit -am"initial commit"

	run "$(pwd)/${FUT}"
	assert_failure
	assert_output "Can't merge; there is no other remote..."
	assert_checkout_clean

	git remote add bare1 "${BARE_REPO_1}"
	git remote add bare2 "${BARE_REPO_2}"

	run "$(pwd)/${FUT}"
	assert_failure
	assert_output "Can't merge; there is more than one other remote..."
	assert_checkout_clean
}

@test "$FUT: fail if working copy is not clean" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "new file" >new-file.txt

	run "$(pwd)/${FUT}"
	assert_failure
	assert_output "Can't merge; working tree is not clean, commit or stash local changes..."

	rm new-file.txt
	echo "addition" >>file1.txt

	run "$(pwd)/${FUT}"
	assert_failure
	assert_output "Can't merge; working tree is not clean, commit or stash local changes..."
}

@test "$FUT: adding a file" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "new file" >new-file.txt
	git add new-file.txt
	git commit -m"New file"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt
	git push

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	git push
}

@test "$FUT: adding a conflicting file" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "new file 1" >new-file.txt
	git add new-file.txt
	git commit -m"New file"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	echo "new file 1" >new-file.txt
	git add new-file.txt
	git commit -m"New file"
	git push

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt

	echo "addition" >>new-file.txt
	git commit -am"addition"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "conflict" >>new-file.txt
	git commit -am"conflict"
	git push

	run "$(pwd)/${FUT}"
	assert_success
	! assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt
}

@test "$FUT: adding ignored files" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "new file 1" >new-file.txt
	echo new-file.txt >>sync-other-remote.ignore.txt
	IGNORE_LIST[${#IGNORE_LIST[@]}]="new-file.txt"
	git add new-file.txt
	git commit -am"New file"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt

	echo "new file 2" >new-file.txt
	git add new-file.txt
	git commit -am"New file"
	git push

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt

	echo "addition" >>new-file.txt
	git commit -am"addition"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "conflict" >>new-file.txt
	git commit -am"conflict"
	git push

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt new-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt new-file.txt

	assert_contents "${CHECKOUT_1}/repo1/new-file.txt" "new file 1" "conflict"
	assert_contents "${CHECKOUT_2}/repo2/new-file.txt" "new file 2" "addition"
}

@test "$FUT: changing shared files" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	echo "additional line" >>shared-file.txt
	git commit -am"additional line"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	sed -e '1d' -i shared-file.txt
	git commit -am"removed first line"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt

	assert_contents "${CHECKOUT_1}/repo1/shared-file.txt" "some more text" "last line" "additional line"
	assert_contents "${CHECKOUT_2}/repo2/shared-file.txt" "some more text" "last line" "additional line"

	echo "one more change" >>shared-file.txt
	git commit -am"last change"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	echo "one more change" >>shared-file.txt
	git commit -am"last change again"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_contents "${CHECKOUT_1}/repo1/shared-file.txt" "some more text" "last line" "additional line" "one more change"
	assert_contents "${CHECKOUT_2}/repo2/shared-file.txt" "some more text" "last line" "additional line" "one more change"

	sed -re 's/last line/not the last line anymore/' -i shared-file.txt
	git commit -am"fix a line"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	sed -re 's/last line/now a conflicting line/' -i shared-file.txt
	git commit -am"make a conflict"

	run "$(pwd)/${FUT}"
	assert_success
	! assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt
}

@test "$FUT: deleting files" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	git rm file1.txt
	git commit -am"removed file 1"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	git rm file2.txt
	git commit -am"removed file 2"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt

	git rm not-synced.txt
	git commit -am"removed not-synced file"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt

	git rm shared-file.txt
	git commit -am"removed shared file"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" not-synced.txt
	assert_files "${CHECKOUT_2}/repo2"
}

@test "$FUT: deleting files on both sides" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	git rm not-synced.txt
	git commit -am"removed not-synced file"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"
	git rm not-synced.txt
	git commit -am"removed not-synced file again"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt file1.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt file2.txt

	git rm shared-file.txt
	git commit -am"removed shared file"
	git push

	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	git rm shared-file.txt
	git commit -am"removed shared file again"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" file1.txt
	assert_files "${CHECKOUT_2}/repo2" file2.txt
}

@test "$FUT: remove and ignore file" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	git rm shared-file.txt
	echo shared-file.txt >>sync-other-remote.ignore.txt
	IGNORE_LIST[${#IGNORE_LIST[@]}]="shared-file.txt"
	git commit -am"removed and ignore"
	git push

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"

	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" not-synced.txt file1.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt
}

@test "$FUT: synchronises branches" {
	cd "${CHECKOUT_1}/repo1" || fail "Failed to change into directory: ${CHECKOUT_1}/repo1"
	git checkout -b test_branch
	echo "branch changes" >branch-file.txt
	git add branch-file.txt
	git commit -am"made branch"
	git upstream

	run "$(pwd)/${FUT}"
	assert_failure
	assert_checkout_clean

	cd "${CHECKOUT_2}/repo2" || fail "Failed to change into directory: ${CHECKOUT_2}/repo2"

	# synchronises master
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	# checks working tree
	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt branch-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt

	git checkout -b test_branch
	run "$(pwd)/${FUT}"
	assert_success
	assert_checkout_clean

	assert_files "${CHECKOUT_1}/repo1" shared-file.txt not-synced.txt file1.txt branch-file.txt
	assert_files "${CHECKOUT_2}/repo2" shared-file.txt not-synced.txt file2.txt branch-file.txt
}
