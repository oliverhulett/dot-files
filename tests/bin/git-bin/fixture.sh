HERE="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
DF_TESTS="$(dirname "$(dirname "${HERE}")")"
DOTFILES="$(dirname "${DF_TESTS}")"
source "${DF_TESTS}/utils.sh"

function fixture_setup()
{
	should_run
	scoped_blank_home
	cp "${DOTFILES}/gitconfig" "${DOTFILES}/gitconfig.home" "${DOTFILES}/gitconfig.optiver" "${HOME}/"
	crudini --inplace --set "${HOME}/gitconfig.home" include path "${HOME}/gitconfig"
	crudini --inplace --set "${HOME}/gitconfig.optiver" include path "${HOME}/gitconfig"
	ln -vfs gitconfig.home "${HOME}/.gitconfig"
	ln -vfs "${DOTFILES}/gitignore" "${HOME}/.gitignore"
	ln -vfs "${DOTFILES}/git_wrappers" "${HOME}/.git_wrappers"

	scoped_mktemp BARE_REPO -d
	scoped_mktemp CHECKOUT -d
	( cd "${BARE_REPO}" && git init --bare )
	( cd "${CHECKOUT}" && git clone "${BARE_REPO}" repo )
	( cd "${CHECKOUT}/repo" && touch nothing && git add nothing && git commit -m"nothing" )

	source "${DOTFILES}/bash_aliases/19-env-git.sh"
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
