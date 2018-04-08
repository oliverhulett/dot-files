#!/bin/bash
## This script is designed to be called regularly from cron.  It'll autocommit your changes to the dot-files repository in a smarter way.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

function report()
{
	echo "$*"
}

function runhere()
{
	if [ "$1" == "-q" ]; then
		shift
	else
		echo "$*"
	fi
	cd "${HERE}" && "$@"
}

IFS=$'\n' read -r -a LAST_COMMIT_MSG <<< "$(runhere -q git log -1 --pretty=%B)"
report "Last commit: ${LAST_COMMIT_MSG[*]}"
THIS_COMMIT_MSG=( "Autocommit from $(hostname)" "$(runhere -q git status -s))" )
report "This commit: ${THIS_COMMIT_MSG[*]}"

runhere git diff --quiet --exit-code && runhere git diff --cached --quiet --exit-code
WC_WAS_CLEAN=$?
report "Working copy was clean: 0 == ${WC_WAS_CLEAN}"

test -n "$(runhere git log master..origin/master --oneline)"
PULL_HAS_COMMITS=$?
report "Pull has commits: 0 == ${PULL_HAS_COMMITS}"
test -n "$(runhere git log origin/master..master --oneline)"
PUSH_HAS_COMMITS=$?
report "Push has commits: 0 == ${PUSH_HAS_COMMITS}"

# First, try to commit existing changes.  If the last commit is unpushed and was an auto-commit, amend it to include these changes, otherwise create a new auto-commit.
report
if [ ${WC_WAS_CLEAN} -ne 0 ]; then
	report "Working copy was not clean..."
	AMEND=
	if [ "${LAST_COMMIT_MSG[0]}" == "${THIS_COMMIT_MSG[0]}" ]; then
		report "Last commit was not an autocommit from this machine, amending..."
		AMEND="--amend"
	fi
	runhere git commit ${AMEND} -a "${THIS_COMMIT_MSG[@]/#/-m/}"
fi

# Second, pull new code.
report
report "Pulling new code from origin..."
runhere git pullme

# Third, if there is an unpushed commit, that wasn't just created or amended (reduce churn) push the commits.
report
if [ ${WC_WAS_CLEAN} -eq 0 ] && [ ${PUSH_HAS_COMMITS} -eq 0 ]; then
	report "Detected unpushed code that wasn't just created or amended, pushing..."
	runhere git push
fi

# Finally, if there have been changes since last time (commits added locally or pulled in) run the tests? and setup-home.sh.
report
if [ ${WC_WAS_CLEAN} -ne 0 ] || [ ${PULL_HAS_COMMITS} -eq 0 ]; then
	report "Detected changes since last run (commits added locally or pulled from origin), running tests and setup-home.sh..."
	echo runhere ./tests/run.sh && echo runhere ./setup-home.sh
fi
