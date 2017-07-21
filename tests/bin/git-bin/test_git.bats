#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="bin/git.sh"

@test "$FUT: expects the same interace as system git" {
	run command git --help
	assert_line --index 0 "usage: git [--version] [--help] [-c name=value]"
	assert_line --index 1 "           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]"
	assert_line --index 2 "           [-p|--paginate|--no-pager] [--no-replace-objects] [--bare]"
	assert_line --index 3 "           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]"
	assert_line --index 4 "           <command> [<args>]"
}

function _gitenv()
{
	"${EXE}" env | command grep "$@"
}
@test "$FUT: prepends git-bin to path" {
	run _gitenv -E '^PATH='
	# git prepends to the path.
	assert_all_lines --partial ":${DOTFILES}/bin/git-bin:"
}

@test "$FUT: proxies git exit code" {
	run "${EXE}" status
	assert_success
	run "${EXE}" status
	assert_success
	run "${EXE}" -h asdf-string-not-close-to-a-git-cmd
	assert_failure
	run "${EXE}" asdf-string-not-close-to-a-git-cmd
	assert_failure
}

@test "$FUT: standard git-exe interface" {
	find "${DOTFILES}/bin/git-bin" \( -type f -or -type l \) -name 'git-*' | while read -r; do
		# git-exe commands are links to executables in the git-bin directory
		assert [ "$(dirname "$(readlink -f "${REPLY}")")" == "${DOTFILES}/bin/git-bin" ]

		GIT_CMD="$(basename "${REPLY}" | sed -re 's/^git-//')"

		# git-exe commands accept -h and --help
		run "${EXE}" "${GIT_CMD}" --help
		assert_success
		run "${EXE}" "${GIT_CMD}" -h
		assert_success
	done
}

@test "$FUT: filter ini-file-leading-space" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"
	cp "${DOTFILES}/.gitattributes" ./
	"${EXE}" add .gitattributes
	"${EXE}" commit -m"Add attributes, including filter for .ini files"

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
	"${EXE}" add file.ini
	run "${EXE}" show :file.ini
	assert_all_lines "	# a comment" \
					 "[section]" \
					 "key = value" \
					 "; another comment" \
					 "[another section]" \
					 "key = values" \
					 "	continued"

	"${EXE}" commit -am"file should be cleaned"
	assert_status ""

	rm file.ini
	"${EXE}" checkout file.ini
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
	"${EXE}" add file
	"${EXE}" commit -m"initial commit"
	HASH="$("${EXE}" rev-parse HEAD)"

	echo "more text" >>file
	"${EXE}" commit -am"new commit"
	assert_status ""
	assert test "$("${EXE}" rev-parse HEAD)" != "${HASH}"

	"${EXE}" undo-commit
	assert_status " M file"
	assert_equal "$("${EXE}" rev-parse HEAD)" "${HASH}"
	assert_contents file "text" "more text"

	echo "change" >file
	"${EXE}" add -A
	assert_status "M  file"

	"${EXE}" unstage
	assert_status " M file"
	assert_contents file "change"

	echo "another change" >file
	echo "new" >new-file
	assert_status " M file" "?? new-file"

	"${EXE}" discard
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

	"${EXE}" which ignore
	echo git ignore '*.txt'
	"${EXE}" ignore '*.txt'
	assert_status "A  .gitignore"
	assert_contents .gitignore '*.txt'

	"${EXE}" commit -am"initial commit"

	echo >>.gitignore

	mkdir emptydir
	touch one two three
	"${EXE}" ignore one two three
	assert_status "M  .gitignore"
	assert_contents .gitignore "one" "three" "two" '*.txt'

	"${EXE}" commit -m"ignored files"

	# globally ignored files.
	touch .project .pydevproject .cproject
	ln -vfs emptydir .settings

	"${EXE}" cleanignored
	assert_status ""
	assert_files .gitignore .project .pydevproject .cproject .settings emptydir
}

@test "$FUT: git cleanbranches" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	"${EXE}" checkout -b testbranch
	run "${EXE}" branch
	assert_all_lines "  master" "* testbranch"

	"${EXE}" upstream

	"${EXE}" checkout -b testbranch2
	run "${EXE}" branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	"${EXE}" upstream

	"${EXE}" cleanbranches
	run "${EXE}" branch
	assert_all_lines "  master" "  testbranch" "* testbranch2"

	"${EXE}" checkout master
	run "${EXE}" branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	"${EXE}" cleanbranches
	run "${EXE}" branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	"${EXE}" push origin --delete testbranch
	"${EXE}" fetch --prune

	run "${EXE}" branch
	assert_all_lines "* master" "  testbranch" "  testbranch2"

	"${EXE}" cleanbranches
	run "${EXE}" branch
	assert_all_lines "* master" "  testbranch2"

	"${EXE}" push origin --delete testbranch2
	"${EXE}" pullb
	run "${EXE}" branch
	assert_all_lines "* master"
}
