#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="git-things/bin/editor.sh"
IS_EXE="false"

# UX design: Show status before commit, show existing msg (offer to use existing msg), offer to show diff at time of msg input.
#            Ask for input (message) first, do book-keeping later.
#            Save message (for possible editing later) if book-keeping fails.

@test "$FUT: master" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

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
	stub vim '*.git/COMMIT_EDITMSG : echo special vim because of e'
	run git commit -a <<<"dDe"
	assert_all_lines "${GIT_STATUS_LINES[@]}" \
					 "${MSG_PROMPT}" \
					 "${GIT_DIFF_LINES[@]}" \
					 "${MSG_PROMPT}" \
					 "${GIT_DIFF_LINES[@]}" \
					 "${MSG_PROMPT}" \
					 "special vim because of e" \
					 "Aborting commit due to empty commit message."
	assert_failure # aborted commit due to empty msg.
	unstub vim

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

	run git commit -a --amend <<<"
yasdf"
	assert_success
	assert_all_lines "${NEW_COMMIT_MSG}" \
					 "# On branch master" \
					 "nothing to commit, working directory clean" \
					 "${MSG_PROMPT}" \
					 "--regexp \[master [0-9a-f]+\] asdf: ${NEW_COMMIT_MSG}" \
					 " 1 file changed, 1 insertion(+)" \
					 " create mode 100644 file"
	assert_equal "$(git log -1 --pretty=%B)" "asdf: ${NEW_COMMIT_MSG}"
}

# Ask about prefixing branch to message if we're on a branch and a message was given.
# If no message was given, automate adding branch name to contents of .git/COMMIT_EDITMSG
# There are two types of branches for this too, feature and fix/work branches, they have different formats.

@test "$FUT: feature branches" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	INITIAL_COMMIT_MSG="using commit --amend makes testing easier"
	BRANCH_NAME="feature/my-feature_description"
	git checkout -b "${BRANCH_NAME}"
	git push --set-upstream origin "${BRANCH_NAME}"
	echo "branch words">file
	git add file
	git commit -am"${INITIAL_COMMIT_MSG}"

	GIT_STATUS_LINES=(
		'# On branch '"${BRANCH_NAME}"
		"# Your branch is ahead of 'origin/${BRANCH_NAME}' by 1 commit."
		'#   (use "git push" to publish your local commits)'
		'#'
		'nothing to commit, working directory clean'
	)
	MSG_PROMPT="Enter a short (single line) commit message.  Press 'e' or enter 'edit' to launch \`vim'.  Press 'd' or enter 'diff' to see the commit diff."
	# Committing shows current commit msg (if present), status, offers diff, accepts simple msg, can fall into vim.
	# can't stub git, from within git /usr/libexec/git-core is prefixed to path and /usr/libexec/git-core/git is found instead of binstub.

	for a in "n" "" "y" "Y" "n" "N"; do
		if [ "$a" == "" ] || [ "$a" == "y" ] || [ "$a" == "Y" ]; then
			PREFIX="my-feature: "
		else
			PREFIX=
		fi
		BRANCH_COMMIT_MSG="Added words to branch of file, yes was the default, but we can specify an answer as well: ${a}."
		run git commit -a --amend <<<"${BRANCH_COMMIT_MSG}
$a"
		assert_success
		assert_all_lines "${INITIAL_COMMIT_MSG}" \
						 "${GIT_STATUS_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "--regexp \[${BRANCH_NAME} [0-9a-f]+\] ${PREFIX}${BRANCH_COMMIT_MSG}" \
						 " 1 file changed, 1 insertion(+)" \
						 " create mode 100644 file"
		assert_equal "$(git log -1 --pretty=%B)" "${PREFIX}${BRANCH_COMMIT_MSG}"
		INITIAL_COMMIT_MSG="${PREFIX}${BRANCH_COMMIT_MSG}"
	done

	for a in "o" "O"; do
		BRANCH_COMMIT_MSG="Added words to branch of file, yes was the default, but we can specify an answer as well: ${a}."
		run git commit -a --amend <<<"${BRANCH_COMMIT_MSG}
${a}asdf"
		assert_success
		assert_all_lines "${INITIAL_COMMIT_MSG}" \
						 "${GIT_STATUS_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "--regexp \[${BRANCH_NAME} [0-9a-f]+\] asdf: ${BRANCH_COMMIT_MSG}" \
						 " 1 file changed, 1 insertion(+)" \
						 " create mode 100644 file"
		assert_equal "$(git log -1 --pretty=%B)" "asdf: ${BRANCH_COMMIT_MSG}"
		INITIAL_COMMIT_MSG="asdf: ${BRANCH_COMMIT_MSG}"
	done
}

@test "$FUT: branch name to prefix" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	MSG_PROMPT="Enter a short (single line) commit message.  Press 'e' or enter 'edit' to launch \`vim'.  Press 'd' or enter 'diff' to see the commit diff."
	COMMIT_MSG="commit on a branch"
	for str in "feature/my-feature_description : my-feature" \
			   "olihul/my-branch_description : my-branch" \
			   "oliver_hulett/my-branch_description : my-branch" \
			   "bugfix/my-ticket_description : my-ticket" \
			   "bugfix/olihul/my-ticket_description : my-ticket" \
			   "feature/olihul/my-feature_description : my-feature" \
			   "feature/my-feature : my-feature" \
			   "olihul/my-branch : my-branch" \
			   "oliver_hulett/my-branch : my-branch" \
			   "bugfix/my-ticket : my-ticket" \
			   "bugfix/olihul/my-ticket : my-ticket"; do
		PREFIX="${str#* : }"
		BRANCH_NAME="${str% : *}"
		git checkout master
		git checkout -b "${BRANCH_NAME}"
		git push --set-upstream origin "${BRANCH_NAME}"
		echo "${BRANCH_NAME}">file
		git add file

		GIT_STATUS_LINES=(
			'# On branch '"${BRANCH_NAME}"
			'# Changes to be committed:'
			'#   (use "git reset HEAD <file>..." to unstage)'
			'#'
			'#	new file:   file'
			'#'
		)
		run git commit -a <<<"${COMMIT_MSG}"
		assert_success
		assert_all_lines "${GIT_STATUS_LINES[@]}" \
						 "${MSG_PROMPT}" \
						 "--regexp \[${BRANCH_NAME} [0-9a-f]+\] ${PREFIX}: ${COMMIT_MSG}" \
						 " 1 file changed, 1 insertion(+)" \
						 " create mode 100644 file"
		assert_equal "$(git log -1 --pretty=%B)" "${PREFIX}: ${COMMIT_MSG}"
	done
}

@test "$FUT: special vim" {
	cd "${CHECKOUT}/repo" || fail "Failed to change into directory: ${CHECKOUT}/repo"

	INITIAL_COMMIT_MSG="Adding file, we'll change it for each commit"
	touch file
	git add file
	git commit -am"${INITIAL_COMMIT_MSG}"

	MSG_PROMPT="Enter a short (single line) commit message.  Press 'e' or enter 'edit' to launch \`vim'.  Press 'd' or enter 'diff' to see the commit diff."
	# Committing shows current commit msg (if present), status, offers diff, accepts simple msg, can fall into vim.
	# can't stub git, from within git /usr/libexec/git-core is prefixed to path and /usr/libexec/git-core/git is found instead of binstub.
	echo "words" >file
	stub vim '-c startinsert .git/COMMIT_EDITMSG : echo commit msg >.git/COMMIT_EDITMSG'
	run git commit -a <<<"e"
	assert_success
	assert_all_lines '# On branch master' \
					 '# Changes to be committed:' \
					 '#   (use "git reset HEAD <file>..." to unstage)' \
					 '#' \
					 '#	modified:   file' \
					 '#' \
					 "${MSG_PROMPT}" \
					 "--regexp \[master [0-9a-f]+\] ${NEW_COMMIT_MSG}" \
					 " 1 file changed, 1 insertion(+)"
	assert_equal "$(git log -1 --pretty=%B)" "commit msg"
	unstub vim

	stub vim '.git/COMMIT_EDITMSG : echo new message >.git/COMMIT_EDITMSG'
	run git commit -a --amend <<<"e"
	assert_success
	assert_all_lines "commit msg" \
					 '# On branch master' \
					 'nothing to commit, working directory clean' \
					 "${MSG_PROMPT}" \
					 "--regexp \[master [0-9a-f]+\] ${NEW_COMMIT_MSG}" \
					 " 1 file changed, 1 insertion(+)"
	assert_equal "$(git log -1 --pretty=%B)" "new message"
	unstub vim
}
