#!/bin/bash
## This script is designed to be called regularly from cron.  It'll autocommit your changes to the dot-files repository in a smarter way.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "${HERE}/lib/script_utils.sh"

function runhere()
{
	cd "${HERE}" && "$@"
}

function git_is_busy()
{
	test -d "$(runhere git rev-parse --git-path rebase-merge)" || test -d "$(runhere git rev-parse --git-path rebase-apply)"
}

reentrance_check

read -r -a LAST_COMMIT_MSG <<< "$(runhere git log -1 --pretty=%B)"
report_good "Last commit: ${LAST_COMMIT_MSG[*]}"

report_cmd runhere git diff --quiet --exit-code && report_cmd runhere git diff --cached --quiet --exit-code
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
	set -x
	CHANGES="$(runhere git status -s)"
	# Autocommit msg format is "Autocommit from <hostname>: X files changed"
	if [ ${PUSH_HAS_COMMITS} -eq 0 ] && [ "${LAST_COMMIT_MSG[0]}" == "Autocommit" ] && [ "${LAST_COMMIT_MSG[1]}" == "from" ] && [ "${LAST_COMMIT_MSG[2]}" == "$(hostname):" ]; then
		report_good "Last commit is unpushed and was an autocommit from this machine, amending..."
		AMEND="--amend"
		CHANGES="$(runhere git log -1 --pretty=%B | tail -n+2)
${CHANGES}"
	fi
	CHANGES="$(echo "${CHANGES}" | LC_ALL=C sort -u)"
	THIS_COMMIT_MSG=( "Autocommit from $(hostname): $(echo "${CHANGES}" | wc -l) files changed" "${CHANGES}" )
	report_cmd runhere git commit ${AMEND} -a "${THIS_COMMIT_MSG[@]/#/-m}"
	set +x
fi

# Second, pull new code.
report_good
report_good "Pulling new code from origin..."
report_cmd runhere git pullme
# Pulling can kick us into a rebase or merge conflict resolution, check for that.
if git_is_busy; then
	report_bad "Pull failed due to conflicts, aborting..."
	if [ -d "$(runhere git rev-parse --git-path rebase-merge)" ]; then
		report_cmd runhere git merge --abort
	elif [ -d "$(runhere git rev-parse --git-path rebase-apply)" ]; then
		report_cmd runhere git rebase --abort
	fi
	exit 1
fi

# Third, if there is an unpushed commit, that wasn't just created or amended (reduce churn) push the commits.
if [ ${WC_WAS_CLEAN} -eq 0 ] && [ ${PUSH_HAS_COMMITS} -eq 0 ]; then
	report_good
	report_good "Detected unpushed code that wasn't just created or amended, pushing..."
	report_cmd runhere git push
fi

# Finally, if there have been changes since last time (commits added locally or pulled in) run the tests? and setup-home.sh.
if [ ${WC_WAS_CLEAN} -ne 0 ] || [ ${PULL_HAS_COMMITS} -eq 0 ]; then
	report_good
	report_good "Detected changes since last run (commits added locally or pulled from origin), running tests and setup-home.sh..."
	report_cmd runhere nice -n 10 ./tests/run.sh ./tests/validate_dot-files.bats && report_cmd runhere ./setup-home.sh
fi
