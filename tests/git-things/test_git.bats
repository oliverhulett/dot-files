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
		assert [ "$man" -nt "$REPLY" ]
		assert [ "$man" -nt "$(readlink -f "$REPLY")" ]

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

@test "$FUT: git ignore" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	git ignore '*.txt'
	if command which git-ignore >/dev/null 2>/dev/null; then
		assert_status "M  .gitignore"
	else
		assert_status "A  .gitignore"
	fi
	assert_contents .gitignore '*.txt'

	git commit -am"initial commit"

	echo >>.gitignore

	mkdir emptydir
	touch one two three
	git ignore one two three
	assert_status "M  .gitignore"
	if command which git-ignore >/dev/null 2>/dev/null; then
		assert_contents .gitignore "*.txt" "" "one" "two" 'three'
	else
		assert_contents .gitignore "one" "three" "two" '*.txt'
	fi

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

ONLY="editor.sh"
@test "$FUT: editor.sh" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	# UX design: Show status before commit, show existing msg (offer to use existing msg), offer to show diff at time of msg input.
	#            Ask for input (message) first, do book-keeping later.
	#            Save message (for possible editing later) if book-keeping fails.

	INITIAL_COMMIT_MSG="Adding file, we'll change it for each commit"
	touch file
	git add file
	git commit -am"${INITIAL_COMMIT_MSG}"

	GIT_STATUS_LINES=(
		'# On branch master'
		'# Changes to be committed:'
		'#   (use "git reset HEAD <file>..." to unstage)'
		'#'
		'#	modified:   file'
		'#'
	)
	MSG_PROMPT="Enter a short (single line) commit message.  Press 'e' or enter 'edit' to launch \`vim'.  Press 'd' or enter 'diff' to see the commit diff."
	# Committing shows current commit msg (if present), status, offers diff, accepts simple msg, can fall into vim.
	# can't stub git, from within git /usr/libexec/git-core is prefixed to path and /usr/libexec/git-core/git is found instead of binstub.
	echo "words" >file
	run git commit -a <<-EOF
	EOF
	assert_failure # aborted commit due to empty msg.
	assert_all_lines "${GIT_STATUS_LINES[@]}" \
					 "${MSG_PROMPT}" \
					 "Aborting commit due to empty commit message."

	# The backspace thing doesn't really work.  For testing purposes, make sure you're overwriting with more characters than you're deleting.
	# In real life, readline will handle this for us, `read' will only see the "final" string.
	for i in "$(printf "e")" \
			 "$(printf "E")" \
			 "$(printf "t\be")" \
			 "$(printf "t\bE")" \
			 "$(printf "sadf\b\b\b\bedit")" \
			 "$(printf "sadf\b\b\b\bEDIT")" \
			 "$(printf "sadf\b\b\b\bEdIt")"; do
		stub vim '*.git/COMMIT_EDITMSG : echo special vim because of '"$i"
		run git commit -a <<<"$i"
		assert_all_lines "${GIT_STATUS_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "special vim because of $i" \
						 "Aborting commit due to empty commit message."
		assert_failure # aborted commit due to empty msg.
		unstub vim
	done

	GIT_DIFF_LINES=(
		'diff --git c/file i/file'
		'--regexp index .+ 100644'
		'--- c/file'
		'+++ i/file'
		'@@ -0,0 +1 @@'
		'+words'
	)
	for i in "$(printf "d")" \
			 "$(printf "D")" \
			 "$(printf "t\bd")" \
			 "$(printf "t\bD")" \
			 "$(printf "sadf\b\b\b\bdiff")" \
			 "$(printf "sadf\b\b\b\bDIFF")" \
			 "$(printf "sadf\b\b\b\bDiFf")"; do
		run git commit -a <<<"$i"
		assert_all_lines "${GIT_STATUS_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "${GIT_DIFF_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "Aborting commit due to empty commit message."
		assert_failure # aborted commit due to empty msg.
	done

	NEW_COMMIT_MSG="Amended commit message, plus some text in the file"
	run git commit -a --amend <<-EOF
		${NEW_COMMIT_MSG}
	EOF
	assert_success
	assert_all_lines "${INITIAL_COMMIT_MSG}" \
					 "${GIT_STATUS_LINES[@]}" \
					 "${MSG_PROMPT}" \
					 "--regexp \[master [0-9a-f]+\] ${NEW_COMMIT_MSG}" \
					 " 1 file changed, 1 insertion(+)" \
					 " create mode 100644 file"
	assert_equal "$(git log -1 --pretty=%B)" "${NEW_COMMIT_MSG}"

	# Ask about prefixing branch to message if we're on a branch and a message was given.
	# If no message was given, automate adding branch name to contents of .git/COMMIT_EDITMSG
	# There are two types of branches for this too, feature and fix/work branches, they have different formats.
}
