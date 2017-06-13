#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

DOT_FILES="$(dirname "${DF_TESTS}")"
IGNORE_LIST="sync-other-remote.ignore.txt"

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
	${IGNORE_LIST}
	.gitignore
	gitignore
	interactive_commands
)
DF_LISTS_OPTIVER=(
	backups.txt
	docker_favourites
	dot-files
	dot-files.3100-centos7dev
	installed-software.txt
	python_setup.txt
)
DF_LISTS_GITHUB=(
	dot-files.loki
	dot-files.odysseus
	dot-files.prometheus
)

@test "Validate: required files exist" {
	declare -a FILES EXES
	if [ "$(git config --get remote.origin.url)" == "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
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
	elif [ "$(git config --get remote.origin.url)" == "https://github.com/oliverhulett/dot-files.git" ]; then
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
	else
		fail "Unexpected git remote url"
	fi
	for f in "${FILES[@]}"; do
		assert test -e "${DOT_FILES}/$f" -a ! -x "${DOT_FILES}/$f"
	done
	for f in "${EXES[@]}"; do
		assert test -x "${DOT_FILES}/$f"
	done
}

@test "Validate: lists are sorted and unique" {
	declare -a LISTS
	if [ "$(git config --get remote.origin.url)" == "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
		LISTS=(
			"${DF_LISTS[@]}"
			"${DF_LISTS_OPTIVER[@]}"
		)
	elif [ "$(git config --get remote.origin.url)" == "https://github.com/oliverhulett/dot-files.git" ]; then
		LISTS=(
			"${DF_LISTS[@]}"
			"${DF_LISTS_GITHUB[@]}"
		)
	else
		fail "Unexpected git remote url"
	fi
	for f in "${LISTS[@]}"; do
		assert_equal \
			"$(command cat "${DOT_FILES}/$f")" \
			"$(command cat "${DOT_FILES}/$f" | sort -u)"
	done
}

@test "Validate: all ignored files exist in at least one of the remotes" {
	OTHER_REMOTE="$(cd "${DOT_FILES}" && git remote | command grep -v origin || true)"
	if [ -z "${OTHER_REMOTE}" ]; then
		skip "cannot verify ignored files exist without other remote"
		return
	fi

	scoped_mktemp CHECKOUT -d
	git clone --depth 1 --branch "$(git this)" "$(git config --get "remote.${OTHER_REMOTE}.url")" "${CHECKOUT}"

	shopt -s nullglob
	while read -r; do
		assert find "${DOT_FILES}" "${CHECKOUT}" -wholename "${REPLY}" -print -quit
	done <"${DOT_FILES}/${IGNORE_LIST}"
}

@test "Validate: dot-files exist" {
	shopt -s nullglob
	if [ "$(git config --get remote.origin.url)" == "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
		for l in dot-files dot-files.3100-centos7dev; do
			while read -r f _; do
				assert test -e "${DOT_FILES}/$f"
			done <"${DOT_FILES}/$l"
		done
	elif [ "$(git config --get remote.origin.url)" == "https://github.com/oliverhulett/dot-files.git" ]; then
		for l in dot-files.loki dot-files.odysseus dot-files.prometheus; do
			while read -r f _; do
				assert test -e "${DOT_FILES}/$f"
			done <"${DOT_FILES}/$l"
		done
	else
		fail "Unexpected git remote url"
	fi
}

@test "Validate: files to backup exist" {
	if [ "$(git config --get remote.origin.url)" != "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
		skip "backup list only exists at Optiver"
		return
	fi
	while read -r; do
		assert test -e "${DOT_FILES}/$REPLY"
	done <"${DOT_FILES}/backups.txt"
}
