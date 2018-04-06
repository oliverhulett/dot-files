#!/bin/bash
## This script is designed to be called regularly from cron.  It'll autocommit your changes to the dot-files repository in a smarter way.
set -x

# First, try to commit existing changes.  If the last commit is unpushed and was an auto-commit, amend it to include these changes, otherwise create a new auto-commit.

# Second, pull new code.

# Third, if there is an unpushed commit, that wasn't just created or amended (reduce churn) push the commits.

# Finally, if there have been changes since last time (commits added locally or pulled in) run the tests? and setup-home.sh.

