#!/usr/bin/env bats

DF_TESTS="$(cd "${BATS_TEST_DIRNAME}" && pwd -P)"
DOTFILES="$(dirname "${DF_TESTS}")"
source "${DF_TESTS}/utils.sh"

FUT="setup-home.sh"

function setup_setup_home()
{
	# We never want to actually do the git pull bits for testing purposes...
	stub git "submodule init" "submodule sync" "submodule update"
}
function teardown_setup_home()
{
	unstub git
}

function assert_is_link()
{
	assert test -L "${HOME}/$2"
	assert_equal "$(readlink -f "${HOME}/$2")" "${DOTFILES}/$1"
}

function _do_test_for_host()
{
	HNAME="$1"
	if [ -e "${DOTFILES}/crontab.${HNAME}" ]; then
		stub crontab "${DOTFILES}/crontab.${HNAME}"
	elif [ -e "${DOTFILES}/crontab" ]; then
		stub crontab "${DOTFILES}/crontab"
	fi

	$EXE

	while read -r SRC LINK; do
		assert_is_link "$SRC" "$LINK"
	done <"${DOTFILES}/dot-files-common"

	if [ -e "${DOTFILES}/dot-files.${HNAME}" ]; then
		while read -r SRC LINK; do
			assert_is_link "$SRC" "$LINK"
		done <"${DOTFILES}/dot-files.${HNAME}"
	elif [ -e "${DOTFILES}/dot-files" ]; then
		while read -r SRC LINK; do
			assert_is_link "$SRC" "$LINK"
		done <"${DOTFILES}/dot-files"
	fi

	if [ -e "${DOTFILES}/crontab.${HNAME}" ] || [ -e "${DOTFILES}/crontab" ]; then
		unstub crontab
	fi
}
@test "$FUT: this host" {
	_do_test_for_host "$(hostname -s | tr '[:upper:]' '[:lower:]')"
}

@test "$FUT: all available hosts" {
	shopt -s nullglob
	for HNAME in $(echo "${DOTFILES}"/{dot-files,crontab}.* | cut -d. -f-1 | sort -u); do
		stub hostname "-s : echo ${HNAME}"
		_do_test_for_host "$HNAME"
		unstub hostname
	done
}

@test "$FUT: default host" {
	refute test -e "${DOTFILES}/dot-files.none"
	refute test -e "${DOTFILES}/crontab.none"
	stub hostname "-s : echo NonE"
	_do_test_for_host none
	unstub hostname
}

@test "$FUT: host specific files" {
	SFX="hsftest"
	refute test -e "${DOTFILES}/dot-files.${SFX}"
	refute test -e "${DOTFILES}/crontab.${SFX}"
	touch "${DOTFILES}/dot-files.${SFX}" "${DOTFILES}/crontab.${SFX}"
	register_teardown_fn rm "${DOTFILES}/dot-files.${SFX}" "${DOTFILES}/crontab.${SFX}"
	echo "dot-files.${SFX} file1" >>"${DOTFILES}/dot-files.${SFX}"
	echo "dot-files.${SFX} file2" >>"${DOTFILES}/dot-files.${SFX}"

	stub hostname "-s : echo ${SFX}"
	_do_test_for_host ${SFX}
	unstub hostname
}

@test "$FUT: github passwd" {
	refute test -f "${HOME}/etc/passwd.github"
	mkdir -p "${HOME}/etc"
	echo "asdf" >"${HOME}/etc/passwd.github"

	_do_test_for_host "$(hostname -s | tr '[:upper:]' '[:lower:]')"

	assert test -f "${HOME}/.git-credentials"
	refute test -L "${HOME}/.git-credentials"
	assert_equal '-rw-------' "$(stat -c %A "${HOME}/.git-credentials")"
	assert_equal 'https://oliverhulett:asdf@github.com' "$(cat "${HOME}/.git-credentials")"
}

@test "$FUT: remove existing dot-file links" {
	ln -s "${BATS_TEST_FILENAME}" "${HOME}/file1"
	assert test -e "${HOME}/file1"
	assert test -L "${HOME}/file1"

	_do_test_for_host "$(hostname -s | tr '[:upper:]' '[:lower:]')"

	refute test -e "${HOME}/file1"
}
