#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="git-things/bin/which.sh"

@test "$FUT: git-executables take precedence over aliases" {
	run git -c "alias.which=!which" which which -a
	assert_all_lines "\`git which' is: ${DOTFILES}/git-things/bin/git-which" \
	                  "              : !which"
}

@test "$FUT: returns success only if all commands exist" {
	run git which pull ls-files push commit
	assert_success

	run git which pull ls-files push commit nada
	assert_failure
}

@test "$FUT: prints commands on a line each" {
	GIT_EXEC_PATH="$(command git --exec-path)"
	run git which pull ls-files push commit
	assert_all_lines "\`git pull' is: ${GIT_EXEC_PATH}/git-pull" \
	                 "\`git ls-files' is: ${GIT_EXEC_PATH}/git-ls-files" \
	                 "\`git push' is: ${GIT_EXEC_PATH}/git-push" \
	                 "\`git commit' is: ${GIT_EXEC_PATH}/git-commit"

	run git which pull nada push commit
	assert_all_lines "\`git pull' is: ${GIT_EXEC_PATH}/git-pull" \
	                 "\`git nada' is: not found" \
	                 "\`git push' is: ${GIT_EXEC_PATH}/git-push" \
	                 "\`git commit' is: ${GIT_EXEC_PATH}/git-commit"
}
