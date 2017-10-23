#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="git-things"
IS_EXE="false"

function _gitenv()
{
	git env | command grep "$@"
}
@test "$FUT: prepends to path and manpath" {
	run _gitenv -E '^PATH='
	# git prepends to the path, so at best we can be second.
	assert_all_lines --partial ":${DOTFILES}/git-things/bin:"
	run _gitenv -E '^MANPATH='
	assert_all_lines --regexp "^MANPATH=${DOTFILES}/git-things/man(:|$)"
}

@test "$FUT: all sub-commands have man pages" {
	find "${DOTFILES}/git-things/bin" \( -type f -or -type l \) -name 'git-*' | while read -r; do
		# git-exe commands are links to executables in the git-bin directory
		assert [ "$(dirname "$(readlink -f "${REPLY}")")" == "${DOTFILES}/git-things/bin" ]
		man="${DOTFILES}/git-things/man/man1/$(basename -- "$REPLY").1.gz"
		assert [ -e "$man" ]

		assert_equal "$("${REPLY}" --help)" "$(gunzip -c "$man")"
	done
}

@test "$FUT: filter ini-file-leading-space" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	cp "${DOTFILES}/.gitattributes" ./
	git add .gitattributes
	git commit -m"Add attributes, including filter for .ini files"

	assert command grep -qE '^gitconfig\*\s+text\s+(.*\s+)?filter=ini-file-leading-space(\s+|$)' .gitattributes

	cat >file.ini <<EOF
	# a comment
	[section]
		key = value
; another comment
[another section]
	key  =	values
			continued
EOF

	# Should run the filter...
	git add file.ini
	run git show :file.ini
	assert_all_lines "	# a comment" \
					 "[section]" \
					 "key = value" \
					 "; another comment" \
					 "[another section]" \
					 "key = values" \
					 "	continued"

	git commit -am"file should be cleaned"
	assert_status ""

	rm file.ini
	git checkout file.ini
	assert_contents file.ini \
		"	# a comment" \
		 "[section]" \
		 "key = value" \
		 "; another comment" \
		 "[another section]" \
		 "key = values" \
		 "	continued"
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

@test "$FUT: git ignoreme" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	git ignoreme '*.txt'
	assert_status "A  .gitignore"
	assert_contents .gitignore '*.txt'

	git commit -am"initial commit"

	echo >>.gitignore

	mkdir emptydir
	touch one two three
	git ignoreme one two three
	assert_status "M  .gitignore"
	assert_contents .gitignore "one" "three" "two" '*.txt'

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
	git pullb
	run git branch
	assert_all_lines "* master"
}
