#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
source "${DF_TESTS}/utils.sh"

DOT_FILES="$(dirname "${DF_TESTS}")"

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
	.gitignore
	gitignore
	interactive_commands
	sync-other-remote.ignore.txt
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
		if [ ! -e "${DOT_FILES}/$f" ]; then
			fail "Expected file does not exist: $f"
		fi
		if [ -x "${DOT_FILES}/$f" ]; then
			fail "File should not be executable: $f"
		fi
	done
	for f in "${EXES[@]}"; do
		if [ ! -x "${DOT_FILES}/$f" ]; then
			fail "Expected executable does not exist: $f"
		fi
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
		if [ "$(command cat "${DOT_FILES}/$f")" != "$(command cat "${DOT_FILES}/$f" | sort -u)" ]; then
			fail "List file is not sorted or not unique: $f"
		fi
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
		if [ ! -e "${DOT_FILES}/${REPLY}" ] && [ ! -e "${CHECKOUT}/${REPLY}" ]; then
			fail "Ignored file does not exist in either remote: $REPLY"
		fi
	done <"${DOT_FILES}/sync-other-remote.ignore.txt"
}

@test "Validate: dot-files exist" {
	declare -a FILES
	if [ "$(git config --get remote.origin.url)" == "ssh://git@git.comp.optiver.com:7999/~olihul/dot-files.git" ]; then
		FILES=( dot-files dot-files.3100-centos7dev )
	elif [ "$(git config --get remote.origin.url)" == "https://github.com/oliverhulett/dot-files.git" ]; then
		FILES=( dot-files.loki dot-files.odysseus dot-files.prometheus )
	else
		fail "Unexpected git remote url"
	fi

	shopt -s nullglob
	for l in "${FILES[@]}"; do
		while read -r f _; do
			if [ ! -e "${DOT_FILES}/$f" ]; then
				fail "Expected dot-file does not exist: $f (from $l)"
			fi
		done <"${DOT_FILES}/$l"
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
	done <"${DOT_FILES}/backups.txt"
}
