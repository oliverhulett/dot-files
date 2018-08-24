# shellcheck shell=bash
## Ignore some shell check errors...
SHELLCHECK_OPTS=

#SHELLCHECK_OPTS+=' -e SC2155'	## Declare and asign separately to avoid masking return values.

SHELLCHECK_OPTS+=' -e SC1090'	## Can't follow non-const source; use `# shellcheck source=...` to specify.
SHELLCHECK_OPTS+=' -e SC1091'	## Not following; file not found, no permissions, or not allowed via -x.
SHELLCHECK_OPTS+=' -e SC2015'	## A && B || C is not if-then-else.

export SHELLCHECK_OPTS
