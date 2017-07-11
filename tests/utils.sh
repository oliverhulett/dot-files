# shellcheck shell=bash
## A collection of utils to help testing with BATS

## Load bats libraries
DF_TESTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "${DF_TESTS}")"
export DF_TESTS DOTFILES
source "${DF_TESTS}/x_helpers/bats-support/load.bash"
source "${DF_TESTS}/x_helpers/bats-assert/load.bash"
source "${DF_TESTS}/x_helpers/bats-file/load.bash"
source "${DF_TESTS}/x_helpers/bats-mock/load.bash"

# Most of these functions only work in setup, teardown, or test functions
function _check_caller_is_test()
{
	if ! ( batslib_is_caller --indirect 'setup' \
			|| batslib_is_caller --indirect "$BATS_TEST_NAME" \
			|| batslib_is_caller --indirect 'teardown' )
	then
		echo "Must be called from \`setup', \`@test' or \`teardown'" \
			| batslib_decorate "ERROR: $*" \
			| fail
		return $?
	fi
}

# The pattern for setup and teardown inheritance is that only one setup() and teardown() function should be defined,
# namely these here.  Test files and test's fixture files should define setup_*() and teardown_*() functions, where
# * will be replaced by each element in turn in the test's fully-qualified name.
# A test's fully-qualified name is: ${DF_TESTS}/<path>/<to>/test_<file>.bats:<name>
function _call_hierarchy()
{
	local s_or_t="$1"
	shift
	local fqtn
	local -a component
	fqtn="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd -P)/$(basename -- "${BATS_TEST_FILENAME%.*}")"
	fqtn="${fqtn#$DF_TESTS}"
	fqtn="${fqtn#/}"
	fqtn="$(echo "${fqtn}" | sed -re 's![^a-zA-Z0-9/]+!_!g')"
	while [ -n "${fqtn}" ]; do
		fqtn="${fqtn#test_}"
		component[${#component[@]}]="${fqtn%%/*}"

		i=${#component[@]}
		i=$((i - 1))
		fqtn="${fqtn#${component[$i]}}"
		fqtn="${fqtn#/}"
	done

	if [ "${s_or_t}" == "teardown" ]; then
		component=( $(echo "${component[@]}" | rev) )
	fi
	declare -a run
	for f in "${component[@]}"; do
		if [ "${s_or_t}" == "teardown" ]; then
			f="$(echo "$f" | rev)"
		fi
		if [ "$(type -t "${s_or_t}_${f}" 2>/dev/null)" == "function" ]; then
			eval "${s_or_t}_${f}" "$@"
			run[${#run[@]}]="${s_or_t}_${f}"
		fi
	done
	declare -F | cut -d' ' -f3 | command grep -E "^${s_or_t}_" | while read -r; do
		if [ "${run[*]}" == "${run[*]/$REPLY}" ]; then
			echo "WARN: Function \`$REPLY' looks like a ${s_or_t} function, but was not found by the setup/teardown inheritance algorithm.  Possible typo?"
		fi
	done
}
function setup()
{
	if ! should_run; then
		return
	fi
	# Default setup() is to skip the test if the program under test doesn't exist or if only one test has been requested
	if [ "${IS_EXE}" == "no" ] || [ "${IS_EXE}" == "false" ]; then
		assert_fut
	else
		assert_fut_exe
	fi

	scoped_blank_home
	populate_home
	# TODO:  Sanitise for location of DOTFILES...
	#source "${HOME}/.bashrc"
	scoped_env PATH="${BATS_MOCK_BINDIR}:${DOTFILES}/bin:${PATH}"

	_call_hierarchy setup "$@"
}
function teardown()
{
	_call_hierarchy teardown "$@"

	# Default teardown() is to fire all registered clean-up functions
	fire_teardown_fns
}

# Mechanism for registering clean-up functions
declare -ga _TEARDOWN_FNS
function register_teardown_fn()
{
	_TEARDOWN_FNS[${#_TEARDOWN_FNS[@]}]="$*"
}
function fire_teardown_fns()
{
	_check_caller_is_test fire_teardown_fns || return $?

	for fn in "${_TEARDOWN_FNS[@]}"; do
		$fn
	done
}

# Skip the test if the program under test doesn't exist
# TODO:  What about aliases and functions?  May need to rename some things and re-work some messages.
function assert_fut()
{
	_check_caller_is_test assert_fut || return $?
	if [ -n "${FUT}" ]; then
		declare -g FUT_PATH
		FUT_PATH="${DOTFILES}/$(cd "${DOTFILES}" && git ls-files -- "${FUT}")"
		if [ ! -f "${FUT_PATH}" ]; then
			skip "Failed to find file under test"
			return 1
		fi
	fi
}
function assert_fut_exe()
{
	_check_caller_is_test assert_fut_exe || return $?
	if [ -n "${FUT}" ]; then
		assert_fut || return $?
		declare -g EXE="${FUT_PATH}"
		if [ ! -x "${EXE}" ]; then
			local shebang
			shebang="$(head -n1 "${EXE}")"
			local interpreter="${shebang:2}"
			if [ "${shebang:0:2}" != '#!' ] || [ ! -e "${interpreter%% *}" ]; then
				skip "Program under test is not executable or has an invalid shebang"
				return 1
			else
				EXE="${interpreter} $EXE"
			fi
		fi
	fi
}

# Skip the test if the user has specified a SKIP list or to ONLY run one test
function should_run()
{
	_check_caller_is_test should_run || return $?
	if [ -n "$ONLY" ]; then
		SUFFIX="$(echo "$ONLY" | sed -re 's/ /_/g')"
		if [ "${BATS_TEST_NAME}" == "${BATS_TEST_NAME%%$SUFFIX}" ]; then
			skip "Single test requested: $ONLY"
			return 1
		fi
	fi
	if [ -n "$SKIP" ]; then
		for t in "${SKIP[@]}"; do
			SUFFIX="$(echo "$t" | sed -re 's/ /_/g')"
			if [ "${BATS_TEST_NAME}" != "${BATS_TEST_NAME%%$SUFFIX}" ]; then
				skip "Skip requested by skip list: $t"
				return 1
			fi
		done
	fi
	return 0
}

# Set and export an environment variable and register it to be restored in teardown.
function scoped_env()
{
	_check_caller_is_test scoped_env || return $?
	for i in "$@"; do
		if [ "${i/=//}" == "$i" ]; then
			local var="$i"
			local val=
		else
			local var="${i%%=*}"
			local val="${i#*=}"
		fi
		if [ -z "${!var}" ]; then
			register_teardown_fn unset "${var}"
		else
			register_teardown_fn export "${var}"="$(eval echo "${!var}")"
		fi
		if [ -z "$val" ]; then
			val="$(eval echo "${!var}")"
		fi
		eval export "${var}"="${val}"
	done
}
function scoped_environment()
{
	scoped_env "$@"
}

# Create a temporary file or directory and register it for removal on teardown.
function scoped_mktemp()
{
	_check_caller_is_test scoped_mktemp || return $?
	local var="$1"
	shift
	local f
	f="$(mktemp -p "${BATS_TMPDIR}" "$@" "${BATS_TEST_NAME}".XXXXXXXX)"
	register_teardown_fn unset "${var}"
	register_teardown_fn rm -rf "$f"
	eval "${var}"="$f"
}

# Set ${HOME} to a blank temporary directory in-case tests want to mutate it.
function new_blank_home()
{
	_check_caller_is_test new_blank_home || return $?
	declare -g _ORIG_HOME="${HOME}"
	local tmphome
	tmphome="$(temp_make --prefix="home")"
	if [ -z "$tmphome" ] || [ "$tmphome" == "$HOME" ]; then
		fail "Failed to setup mock \$HOME"
		return $?
	else
		export HOME="$tmphome"
	fi
}
function assert_home_is_temp()
{
	if [ -z "${_ORIG_HOME}" ]; then
		fail "\$_ORIG_HOME not set; can't teardown blank home"
		return 1
	elif [ "${HOME}" == "${_ORIG_HOME}" ]; then
		fail "\$HOME wasn't changed; not deleting original \$HOME"
		return 1
	fi
	return 0
}
function destroy_blank_home()
{
	_check_caller_is_test destroy_blank_home || return $?
	# Paranoid about deleting $HOME.  `temp_del` should only delete things it created.
	# `fail` doesn't actually work here?
	assert_home_is_temp
	temp_del "${HOME}"
	export HOME="${_ORIG_HOME}"
}
function scoped_blank_home()
{
	new_blank_home
	register_teardown_fn destroy_blank_home
}
function populate_home()
{
	_set -e
	assert_home_is_temp
	stub git "submodule init" "submodule sync" "submodule update"

	if [ -e "${DOTFILES}/crontab" ]; then
		stub crontab '*'
	fi

	# Calling `hostname` will return a 'none', meaning only the common stuff will be installed.
	SFX="none.${RANDOM}"
	stub hostname "-s : echo ${SFX}"

	refute test -e "${DOTFILES}/crontab.${SFX}"
	refute test -s "${DOTFILES}/dot-files.${SFX}"
	touch "${DOTFILES}/dot-files.${SFX}"

	"${DOTFILES}/setup-home.sh"

	rm "${DOTFILES}/dot-files.${SFX}" 2>/dev/null || true

	# Local git settings are needed, even if the common stuff didn't install them.
	rm "${HOME}/.gitconfig.local" 2>/dev/null || true
	cat >"${HOME}/.gitconfig.local" <<-EOF
	[user]
	name = Me
	email = me@here
	EOF

	if [ -e "${DOTFILES}/crontab" ]; then
		unstub crontab
	fi
	unstub hostname
	unstub git
	_restore e
}

# A common pattern is to assert all lines of output.  Each argument is a line, in order.  All lines must be specified.
function assert_all_lines()
{
	_check_caller_is_test assert_all_lines || return $?
	local GLOBAL_REGEX_OR_PARTIAL=
	if [ "$1" == "--regexp" ] || [ "$1" == "--partial" ]; then
		GLOBAL_REGEX_OR_PARTIAL="$1"
		shift
	fi
	local errs=0
	local cnt=0
	for l in "$@"; do
		local LOCAL_REGEX_OR_PARTIAL
		LOCAL_REGEX_OR_PARTIAL="$(echo "$l" | cut -d' ' -f1)"
		if [ "$LOCAL_REGEX_OR_PARTIAL" == "--regexp" ] || [ "$LOCAL_REGEX_OR_PARTIAL" == "--partial" ]; then
			l="$(echo "$l" | cut -d' ' -f2-)"
		else
			LOCAL_REGEX_OR_PARTIAL=
		fi
		## Can't quote {GLOBAL,LOCAL}_REGEX_OR_PARTIAL because they'll be interpreted as "empty" lines and not match.
		# shellcheck disable=SC2086
		assert_line --index $cnt ${GLOBAL_REGEX_OR_PARTIAL} ${LOCAL_REGEX_OR_PARTIAL} "$l" || errs=$((errs + 1))
		cnt=$((cnt + 1))
	done
	## ${lines} is part of bash-support.
	# shellcheck disable=SC2154
	if [ $cnt -lt ${#lines[@]} ]; then
		(
			echo "Found more lines of output than expected.  Additional lines:"
			for idx in $(seq $cnt $((${#lines[@]} - 1))); do
				echo -e "\t> ${lines[$idx]}"
			done
		) | fail
		errs=$((errs + ${#lines[@]} - cnt))
	fi
	return $errs
}

## TODO:  These are generally useful, we should move them somewhere common and not test related.
declare -ga _SET_LIST
function _set()
{
	for a in "$@"; do
		for (( i=1; i<${#a}; i++ )); do
			v="${a:$i:1}"
			eval "declare -g _set${v}=+${v}"
			[[ $- == *${v}* ]] && eval "_set${v}=-${v}"
			_SET_LIST=( ${_SET_LIST[@]/$v} )
			_SET_LIST[${#_SET_LIST[@]}]="$v"
		done
		set "$a"
	done
}
function _restore()
{
	for a in "$@"; do
		for (( i=0; i<${#a}; i++ )); do
			v="${a:$i:1}"
			eval "set \${_set${v}:?}"
			_SET_LIST=( ${_SET_LIST[@]/$v} )
		done
	done
}
function _restore_all()
{
	_restore "${_SET_LIST[@]}"
}
