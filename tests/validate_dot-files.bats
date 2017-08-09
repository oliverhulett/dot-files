#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

DF_FILES=(
	bash_common.sh
	trap_stack.sh
	bash_logout
	bash_profile
	bashrc
	profile
	gitconfig
	vimrc
)
DF_FILES_OPTIVER=(
	autocommit.service
	crontab
	crontab.3100-centos7dev
	gitconfig.optiver
)
DF_FILES_GITHUB=(
	crontab.loki
	crontab.prometheus
	gitconfig.home
)

DF_EXES=(
	lessfilter
	setup-home.sh
	sync-other-remote.sh
)
DF_EXES_OPTIVER=(
	autocommit.sh
	backup.sh
)
DF_EXES_GITHUB=()

DF_LISTS=(
	.gitignore
	dot-files-common
	gitignore
	interactive_commands
	sync-other-remote.ignore.txt
)
DF_LISTS_OPTIVER=(
	backups.txt
	docker_favourites
	dot-files
	dot-files.3100-centos7dev
	python_setup.txt
)
DF_LISTS_GITHUB=(
	dot-files.loki
	dot-files.odysseus
	dot-files.prometheus
)

function setup()
{
	:
}

@test "Validate: required files exist" {
	declare -a FILES EXES
	case "$(git config --get remote.origin.url)" in
		"ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" )
			FILES=(
				"${DF_LISTS[@]}"
				"${DF_FILES[@]}"
				"${DF_LISTS_OPTIVER[@]}"
				"${DF_FILES_OPTIVER[@]}"
			)
			EXES=(
				"${DF_EXES[@]}"
				"${DF_EXES_OPTIVER[@]}"
			)
			;;
		"https://github.com/oliverhulett/dot-files.git" | \
		"git@github.com:oliverhulett/dot-files.git" )
			FILES=(
				"${DF_LISTS[@]}"
				"${DF_FILES[@]}"
				"${DF_LISTS_GITHUB[@]}"
				"${DF_FILES_GITHUB[@]}"
			)
			EXES=(
				"${DF_EXES[@]}"
				"${DF_EXES_GITHUB[@]}"
			)
			;;
		* )
			fail "Unexpected git remote url"
			;;
	esac
	for f in "${FILES[@]}"; do
		if [ ! -e "${DOTFILES}/$f" ]; then
			fail "Expected file does not exist: $f"
		fi
		if [ -x "${DOTFILES}/$f" ]; then
			fail "File should not be executable: $f"
		fi
	done
	for f in "${EXES[@]}"; do
		if [ ! -x "${DOTFILES}/$f" ]; then
			fail "Expected executable does not exist: $f"
		fi
	done
}

@test "Validate: lists are sorted and unique" {
	declare -a LISTS
	case "$(git config --get remote.origin.url)" in
		"ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" )
			LISTS=(
				"${DF_LISTS[@]}"
				"${DF_LISTS_OPTIVER[@]}"
			)
			;;
		"https://github.com/oliverhulett/dot-files.git" | \
		"git@github.com:oliverhulett/dot-files.git" )
			LISTS=(
				"${DF_LISTS[@]}"
				"${DF_LISTS_GITHUB[@]}"
			)
			;;
		* )
			fail "Unexpected git remote url"
			;;
	esac
	for f in "${LISTS[@]}"; do
		if [ "$(command cat "${DOTFILES}/$f")" != "$(command cat "${DOTFILES}/$f" | sort -u)" ]; then
			fail "List file is not sorted or not unique: $f"
		fi
	done
}

@test "Validate: all ignored files exist in at least one of the remotes" {
	OTHER_REMOTE="$(cd "${DOTFILES}" && git remote | command grep -v origin || true)"
	if [ -z "${OTHER_REMOTE}" ]; then
		skip "cannot verify ignored files exist without other remote"
		return
	fi

	scoped_mktemp CHECKOUT -d
	git clone --depth 1 --branch "$(git this)" "$(git config --get "remote.${OTHER_REMOTE}.url")" "${CHECKOUT}"

	shopt -s nullglob
	while read -r; do
		if [ ! -e "${DOTFILES}/${REPLY}" ] && [ ! -e "${CHECKOUT}/${REPLY}" ]; then
			fail "Ignored file does not exist in either remote: $REPLY"
		fi
	done <"${DOTFILES}/sync-other-remote.ignore.txt"
}

@test "Validate: ignored file list is not in ignored file list" {
	refute command grep -wqE '^sync-other-remote.ignore.txt$' "${DOTFILES}/sync-other-remote.ignore.txt"
}

function _get_dot_files()
{
	declare -ag FILES
	case "$(git config --get remote.origin.url)" in
		"ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" )
			FILES=( dot-files dot-files.3100-centos7dev )
			;;
		"https://github.com/oliverhulett/dot-files.git" | \
		"git@github.com:oliverhulett/dot-files.git" )
			FILES=( dot-files.loki dot-files.odysseus dot-files.prometheus )
			;;
		* )
			fail "Unexpected git remote url"
			;;
	esac
}
@test "Validate: dot-files exist" {
	_get_dot_files

	shopt -s nullglob
	for l in "${FILES[@]}"; do
		while read -r f _; do
			if [ ! -e "${DOTFILES}/$f" ]; then
				fail "Expected dot-file does not exist: $f (from $l)"
			fi
		done <"${DOTFILES}/$l"
	done
}

@test "Validate: dot-files do not overwrite dot-files-common" {
	_get_dot_files

	for l in "${FILES[@]}"; do
		while read -r _ DEST; do
			if grep -qw "${DEST}" <(cut -d' ' -f2 "${DOTFILES}/dot-files-common"); then
				fail "Specific dot-file overwrites destination from dot-files-common: ${DEST} (from $l)"
			fi
		done <"${DOTFILES}/$l"
	done
}

@test "Validate: dot-files-common contains minimum required set of files" {
	MINIMUM_SET=(
		.bash_aliases/30-aliases.sh
		.bash_logout
		.bash_profile
		.bashrc
		.git_wrappers
		.gitconfig
		.gitignore
		.interactive_commands
		.lessfilter
		.profile
		.profile
		.vim
		.vimrc
	)
	for f in "${MINIMUM_SET[@]}"; do
		assert grep -qw "$f" <(cut -d' ' -f2 "${DOTFILES}/dot-files-common")
	done
}

@test "Validate: crontabs are not empty" {
	for f in "${DOTFILES}/"crontab*; do
		if [ ! -s "$f" ]; then
			fail "Crontab file is empty: $(basename -- "$f")"
		fi
	done
}

@test "Validate: files to backup exist" {
	if [ "$(git config --get remote.origin.url)" != "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
		skip "backup list only exists at Optiver"
		return
	fi
	while read -r; do
		if [ ! -e "/$REPLY" ]; then
			fail "File to backup does not exist: $REPLY"
		fi
	done <"${DOTFILES}/backups.txt"
}

@test "Validate: bats is a link to our submodule" {
	assert test -L "${DOTFILES}/bin/bats"
	assert_equal "$(readlink -f "${DOTFILES}/bin/bats")" "$(readlink -f "${DOTFILES}/tests/x_helpers/bats/bin/bats")"
}

@test "Validate: no tests are being skipped by \$ONLY= or \$SKIP=" {
	FILES=(
		$(find "${DOTFILES}/tests" \
			\( -name x_helpers -prune -or -true \) \
			-type f -name '*.bats' -not -name 'test_tests-utils.bats' -not -name 'validate_dot-files.bats' \
			\( -exec grep -qw ONLY= "{}" \; -or -exec grep -qw SKIP= "{}" \; \) \
			-print \
		)
	)
	if [ ${#FILES[@]} -ne 0 ]; then
		fail "Tests being skipped by \$ONLY= or \$SKIP=; these are intended for debugging only.  (in ${FILES[*]})"
	fi
}
