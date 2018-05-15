#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

DF_FILES=(
	gitconfig
	gitconfig.atlassian
	gitconfig.github
	vimrc
)

DF_SOURCED_SCRIPTS=(
	bash_common.sh
	bash_logout
	bash_profile
	bashrc
	profile
	trap_stack.sh
	$(cd "${DOTFILES}" && echo bash-aliases/*)
)

DF_CRONTABS=( $(cd "${DOTFILES}" && echo crontab.*) )

DF_EXES=(
	autocommit.sh
	backup.sh
	lessfilter
	nansible.sh
	setup-home.sh
)

DF_LISTS=(
	.gitignore
	backups.c02w104ahtdg
	backups.c02w104ahtdg.exclude
	backups.loki
	backups.loki.exclude
	backups.odysseus
	backups.odysseus.exclude
	backups.prometheus
	backups.prometheus.exclude
	dot-files-common
	dot-files.c02w104ahtdg
	dot-files.loki
	dot-files.odysseus
	dot-files.prometheus
	eclipse-user-dictionary.txt
	gitignore
	interactive_commands
)

function setup()
{
	:
}

@test "Validate: required files exist and are committed" {
	for f in "${DF_LISTS[@]}" "${DF_CRONTABS[@]}" "${DF_SOURCED_SCRIPTS[@]}" "${DF_FILES[@]}"; do
		if [ ! -e "${DOTFILES}/$f" ]; then
			fail "Expected file does not exist: $f"
		fi
		if [ -x "${DOTFILES}/$f" ]; then
			fail "File should not be executable: $f"
		fi
		if ! ( cd "${DOTFILES}" && git ls-files --error-unmatch -- "$f" >/dev/null 2>/dev/null ); then
			fail "Expected file is not committed: $f"
		fi
	done
	for f in "${DF_EXES[@]}"; do
		if [ ! -x "${DOTFILES}/$f" ]; then
			fail "Expected executable does not exist: $f"
		fi
		if ! ( cd "${DOTFILES}" && git ls-files --error-unmatch -- "$f" >/dev/null 2>/dev/null ); then
			fail "Expected file is not committed: $f"
		fi
	done
}

@test "Validate: source dot-files exist and are committed" {
	for f in "${DOTFILES}/dot-files-common" "${DOTFILES}"/dot-files.*; do
		# shellcheck disable=SC2094
		while read -r df _; do
			if [ ! -e "${DOTFILES}/$df" ]; then
				fail "Source dot-file does not exist: $df from: $f"
			fi
			if ! ( cd "${DOTFILES}" && git ls-files --error-unmatch -- "$df" >/dev/null 2>/dev/null ); then
				fail "Source dot-file is not committed: $df from: $f"
			fi
		done <"$f"
	done
}

@test "Validate: sourced shell scripts start with shellcheck shell=bash" {
	for f in "${DF_SOURCED_SCRIPTS[@]}"; do
		if [ "$(command head -n1 "${DOTFILES}/$f")" != "# shellcheck shell=sh" ] && [ "$(command head -n1 "${DOTFILES}/$f")" != "# shellcheck shell=bash" ]; then
			fail "Sourced shell script does not start with shellcheck shell=bash as expected: $f"
		fi
	done
}

@test "Validate: crontabs have preamble" {
	for f in "${DF_CRONTABS[@]}"; do
		if [ "$f" == "crontab.c02w104ahtdg" ]; then
			h="/Users/ohulett"
		else
			h="/home/ols"
		fi
		# CRONTAB_PREAMBLE should include the empty line at the end.
		CRONTAB_PREAMBLE=$(
			cat <<-EOF
				## This master file for this crontab is part of this user's ~/dot-files repository.
				## Edit that file always and then run ~/dot-files/setup-home.sh to install it.
				## Never use \`crontab -e\` or your changes may be overwritten.
				HOME=$h
				SHELL=/bin/bash
				PATH=$h/dot-files/bin:/usr/local/bin:/usr/bin:/bin

			EOF
		)
		if [ "$(command head -n6 "${DOTFILES}/$f")" != "${CRONTAB_PREAMBLE}" ]; then
			fail "Crontab does not have expected preamble: $f\n$(diff <(echo "${CRONTAB_PREAMBLE}") <(command head -n6 "${DOTFILES}/$f"))"
		fi
	done
}

@test "Validate: lists are sorted and unique" {
	for f in "${DF_LISTS[@]}"; do
		if [ "$(command cat "${DOTFILES}/$f")" != "$(command cat "${DOTFILES}/$f" | LC_ALL=C sort -u)" ]; then
			fail "List file is not sorted or not unique: $f"
		fi
	done
}

@test "Validate: dot-files exist" {
	FILES=( dot-files.loki dot-files.odysseus dot-files.prometheus )

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
	FILES=( dot-files.loki dot-files.odysseus dot-files.prometheus )

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
		.bash-aliases/30-aliases.sh
		.bash_logout
		.bash_profile
		.bashrc
		.git-wrappers
		.gitconfig
		.gitignore
		.interactive_commands
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
	for f in "${DF_CRONTABS[@]}"; do
		if [ ! -s "${DOTFILES}/$f" ]; then
			fail "Crontab file is empty: $(basename -- "$f")"
		fi
	done
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
