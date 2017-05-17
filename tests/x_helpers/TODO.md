Things about bats and bats plugin's that I'd like to fix and/or change...

* Things I've already mentioned in bats-mock/TODO.md
* `temp_del` should only delete things created with `temp_make`
* `temp_make --prefix` doesn't work?
* Port some of my register teardown magic
* Better error reporting hooks.  Sometimes stderr is given when a test fails sometimes it isn't, provide a mechanism for reporting errors so they're all displayed when a failure occurs.
* `expect_*` to match all of the `assert_*` functions.  Report the error and fail the test, but don't exit immediately
* Print (optionally) saved command output on failure.  Alternatively at least give the saved command output file so the user can see it.
* `fail` (and presumably `assert`?) commands don't fail tests when called from setup/teardown?
* `assert_output` to take an argument per line and additionally assert number of lines of output is a no-brainer.  (Or maybe a differently named assertion to preserve backwards compatibility.)  (Port `assert_all_lines` and associated tests from utils.sh)
* Ability to run single test from a bats file.  Maybe `bats file.bats:<test number>`?  Might also need a --list feature to determine the test numbers.
* Ability to run tests in random order (to ensure no state is carried over.)  Can this work with the above feature?  If so how?
* Report timing results and per suite timing results.
* `fail` (via `batslib_err`) don't handle escape characters in arguments, should print with `echo -e`.
* `assert_output` and `assert_line` should quote expected and actual output when printing so we can see whitespace differences.
* Ability to add custom messages to the output of failed assertions.
* Some evidence of cleanup failures...
