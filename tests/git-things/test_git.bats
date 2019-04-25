#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

function _gitenv()
{
	git env | command grep "$@"
}

@test "git-things: prepends to path and manpath" {
	run _gitenv -E '^PATH='
	# git prepends to the path, so at best we can be second.
	assert_all_lines --partial ":${DOTFILES}/git-things/bin:"
	run _gitenv -E '^MANPATH='
	assert_all_lines --regexp "^MANPATH=${DOTFILES}/git-things/man(:|$)"
}

@test "git-things: all sub-commands have man pages" {
	find "${DOTFILES}/git-things/bin" \( -type f -or -type l \) -name 'git-*' | while read -r; do
		# git-exe commands are links to executables in the git-bin directory
		assert [ "$(dirname "$(readlink -f "${REPLY}")")" == "${DOTFILES}/git-things/bin" ]
		man="${DOTFILES}/git-things/man/man1/$(basename -- "$REPLY").1.gz"
		assert [ -e "$man" ]

		assert_equal "$("${REPLY}" --help)" "$(gunzip -c "$man")"
	done
}

@test "git-things: github username and e-mail are correct" {
	rm "${HOME}/.gitconfig.local"
	( cd "${HOME}" && ln -s "${DOTFILES}/gitconfig.github" .gitconfig.local )
	run git whoami
	assert_output "Oliver Hulett <oliver.hulett@gmail.com>"
}

@test "git-things: git ctrl+z; discard, unstage, undo-commit" {
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

@test "git-things: git ignoreme" {
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
	assert_contents .gitignore '*.txt' "one" "three" "two"

	git commit -m"ignored files"

	# globally ignored files.
	touch .project .pydevproject .cproject anything.iml
	ln -vfs emptydir .settings
	ln -vfs emptydir .idea

	git cleanme
	assert_status ""
	assert_files .gitignore .project .pydevproject .cproject .settings emptydir .idea anything.iml
}
