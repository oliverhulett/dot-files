#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

export FUT="gitconfig"
export IS_EXE="no"

function setup_gitconfig()
{
	rm "${HOME}/.gitconfig.local"
	_link_local_gitconfig github

	scoped_mktemp BARE_REPO -d
	scoped_mktemp CHECKOUT -d
	( cd "${BARE_REPO}" && git init --bare )
	( cd "${CHECKOUT}" && git clone "${BARE_REPO}" repo )
	( cd "${CHECKOUT}/repo" && touch nothing && git add nothing && git commit -m"nothing" )
}

function _link_local_gitconfig()
{
	ln -fsv "${DOTFILES}/gitconfig.$1" "${HOME}/.gitconfig.local"
}

function assert_files()
{
	assert_equal "$(find ./ -xdev -not -name '.' -not \( -name '.git' -prune \) -print | sort)" \
				 "$(printf "./%s\n" "nothing" "$@" | sort -u)"
}

function assert_contents()
{
	run command cat "$1"
	shift
	assert_all_lines "$@"
}

function assert_status()
{
	run git status -s
	assert_all_lines "$@"
}

@test "$FUT: github username and e-mail are correct" {
	_link_local_gitconfig github
	run git whoami
	assert_output "Oliver Hulett <oliver.hulett@gmail.com>"
}

@test "$FUT: git ctrl+z; discard, unstage, undo-commit" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	echo "text" >file
	git add file
	git commit -m"initial commit"
	HASH="$(git rev-parse HEAD)"

	echo "more text" >>file
	git commit -am"new commit"
	assert_status ""
	assert test "$(git rev-parse HEAD)" != "${HASH}"

	git undo-commit
	assert_status " M file"
	assert_equal "$(git rev-parse HEAD)" "${HASH}"
	assert_contents file "text" "more text"

	echo "change" >file
	git add -A
	assert_status "M  file"

	git unstage
	assert_status " M file"
	assert_contents file "change"

	echo "another change" >file
	echo "new" >new-file
	assert_status " M file" "?? new-file"

	git discard
	assert_files file new-file
	assert_status "?? new-file"
	assert_contents file "text"
	assert_contents new-file "new"
	rm new-file
}

@test "$FUT: git ignore" {
	if command which git-ignore >/dev/null 2>/dev/null; then
		skip "\`git ignore' points to an executable, so my alias won't work."
		return
	fi
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	git which ignore
	echo git ignore '*.txt'
	git ignore '*.txt'
	assert_status "A  .gitignore"
	assert_contents .gitignore '*.txt'

	git commit -am"initial commit"

	echo >>.gitignore

	mkdir emptydir
	touch one two three
	git ignore one two three
	assert_status "M  .gitignore"
	assert_contents .gitignore '*.txt' "one" "three" "two"

	git commit -m"ignored files"

	# globally ignored files.
	touch .project .pydevproject .cproject
	ln -vfs emptydir .settings

	git cleanignored
	assert_status ""
	assert_files .gitignore .project .pydevproject .cproject .settings emptydir
}

@test "$FUT: git cleanbranches" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	git checkout -b testbranch
	run git branch
	assert_all_lines "  master" "* testbranch"

	git upstream

	git checkout -b testbranch2
	run git branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	git upstream

	git cleanbranches
	run git branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	git checkout master
	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git cleanbranches
	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git push origin --delete testbranch
	git fetch --prune

	run git branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	git cleanbranches
	run git branch
	assert_all_lines "* master" "  testbranch2"

	git push origin --delete testbranch2
	git pullme
	run git branch
	assert_all_lines "* master"
}
