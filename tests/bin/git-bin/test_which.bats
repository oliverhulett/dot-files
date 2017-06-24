#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
DF_TESTS="$(dirname "$(dirname "${HERE}")")"
DOTFILES="$(dirname "${DF_TESTS}")"
source "${HERE}/fixture.sh"

FUT="bin/git-bin/which.sh"

function setup()
{
	fixture_setup
	assert_fut_exe
}

@test "$FUT: git-executables take precedence over aliases" {
	run git which which
	assert_all_lines "\`git which' is: ${DOTFILES}/bin/git-bin/git-which"

	git config --global --add alias.which "!echo not my command"

	run git which which
	assert_all_lines "\`git which' is: ${DOTFILES}/bin/git-bin/git-which"
}

@test "$FUT: takes --help argument" {
	run git which -h
	assert_success

#	run git which --help
#	assert_success
}

@test "$FUT: returns success only if all commands exist" {
	run git which pull ls-files push commit
	assert_success

	run git which pull ls-files push commit nada
	! assert_success
}

@test "$FUT: prints each command on a line each" {
	run git which pull ls-files push commit
	assert_all_lines "\`git pull' is: /usr/lib/git-core/git-pull" \
	                 "\`git ls-files' is: /usr/lib/git-core/git-ls-files" \
	                 "\`git push' is: /usr/lib/git-core/git-push" \
	                 "\`git commit' is: /usr/lib/git-core/git-commit"

	run git which pull nada push commit
	assert_all_lines "\`git pull' is: /usr/lib/git-core/git-pull" \
	                 "\`git nada' is: " \
	                 "\`git push' is: /usr/lib/git-core/git-push" \
	                 "\`git commit' is: /usr/lib/git-core/git-commit"
}
