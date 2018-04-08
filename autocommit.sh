#!/bin/bash
## This script is designed to be called regularly from cron.  It'll autocommit your changes to the dot-files repository in a smarter way.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

export TERM="${TERM:-xterm-256color}"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
WHITE="$(tput bold)$(tput setaf 7)"
RESET="$(tput sgr0)"

function report_good()
{
	echo -e "${GREEN}" "$*" "${RESET}"
}

function report_bad()
{
	echo -e "${RED}" "$*" "${RESET}"
}

function runhere()
{
	if [ "$1" == "-q" ]; then
		shift
	else
		echo -e "${WHITE}""$*""${RESET}"
	fi
	cd "${HERE}" && "$@"
}

function git_is_busy()
{
	test -d "$(runhere -q git rev-parse --git-path rebase-merge)" || test -d "$(runhere -q git rev-parse --git-path rebase-apply)"
}

## TODO: reentrance...

if git_is_busy; then
	report_bad "Git is busy with an interactive command, we can't interrupt..."
	exit 1
fi

read -r -a LAST_COMMIT_MSG <<< "$(runhere -q git log -1 --pretty=%B)"
report_good "Last commit: ${LAST_COMMIT_MSG[*]}"
CHANGES="$(runhere -q git status -s)"
THIS_COMMIT_MSG=( "Autocommit from $(hostname): $(echo "${CHANGES}" | wc -l) files changed" "${CHANGES}" )
report_good "This commit: ${THIS_COMMIT_MSG[*]}"

runhere git diff --quiet --exit-code && runhere git diff --cached --quiet --exit-code
WC_WAS_CLEAN=$?
report_good "Working copy was clean: 0 == ${WC_WAS_CLEAN}"

test -n "$(runhere git log master..origin/master --oneline)"
PULL_HAS_COMMITS=$?
report_good "Pull has commits: 0 == ${PULL_HAS_COMMITS}"
test -n "$(runhere git log origin/master..master --oneline)"
PUSH_HAS_COMMITS=$?
report_good "Push has commits: 0 == ${PUSH_HAS_COMMITS}"

# First, try to commit existing changes.  If the last commit is unpushed and was an auto-commit, amend it to include these changes, otherwise create a new auto-commit.
report_good
if [ ${WC_WAS_CLEAN} -ne 0 ]; then
	report_good "Working copy was not clean..."
	AMEND=
	# Autocommit msg format is "Autocommit from <hostname>..."
	read -r -a TCM_FIRST_TOKEN <<< "${THIS_COMMIT_MSG[0]}"
	if [ "${LAST_COMMIT_MSG[0]}" == "${TCM_FIRST_TOKEN[0]}" ] && [ "${LAST_COMMIT_MSG[1]}" == "${TCM_FIRST_TOKEN[1]}" ] && [ "${LAST_COMMIT_MSG[2]}" == "${TCM_FIRST_TOKEN[2]}" ]; then
		report_good "Last commit was an autocommit from this machine, amending..."
		AMEND="--amend"
	fi
	runhere git commit ${AMEND} -a "${THIS_COMMIT_MSG[@]/#/-m}"
fi

# Second, pull new code.
report_good
report_good "Pulling new code from origin..."
runhere git pullme
# Pulling can kick us into a rebase or merge conflict resolution, check for that.
if git_is_busy; then
	report_bad "Pull failed due to conflicts, aborting..."
	if [ -d "$(runhere -q git rev-parse --git-path rebase-merge)" ]; then
		runhere git merge --abort
	elif [ -d "$(runhere -q git rev-parse --git-path rebase-apply)" ]; then
		runhere git rebase --abort
	fi
	exit 1
fi

# Third, if there is an unpushed commit, that wasn't just created or amended (reduce churn) push the commits.
if [ ${WC_WAS_CLEAN} -eq 0 ] && [ ${PUSH_HAS_COMMITS} -eq 0 ]; then
	report_good
	report_good "Detected unpushed code that wasn't just created or amended, pushing..."
	runhere git push
fi

# Finally, if there have been changes since last time (commits added locally or pulled in) run the tests? and setup-home.sh.
report_good
if [ ${WC_WAS_CLEAN} -ne 0 ] || [ ${PULL_HAS_COMMITS} -eq 0 ]; then
	report_good "Detected changes since last run (commits added locally or pulled from origin), running tests and setup-home.sh..."
	runhere ./tests/run.sh && runhere ./setup-home.sh
fi
