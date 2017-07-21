#!/usr/bin/env bats

HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${HERE}/fixture.sh"

FUT="bin/git-bin/which.sh"

ONLY="git-executables take precedence over aliases"
@test "$FUT: git-executables take precedence over aliases" {
	( set -x; git -c "alias.which=!which" which which -a )
	run git -c "alias.which=!which" which which -a
	assert_all_lines "\`git which' is: ${DOTFILES}/bin/git-bin/git-which" \
	                 "\`git which' is: !which"
}

@test "$FUT: returns success only if all commands exist" {
	run git which pull ls-files push commit
	assert_success

	run git which pull ls-files push commit nada
	assert_failure
}

@test "$FUT: prints commands on a line each" {
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
