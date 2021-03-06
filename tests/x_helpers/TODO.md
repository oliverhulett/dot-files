Things about bats and bats plugin's that I'd like to fix and/or change...

* Things I've already mentioned in bats-mock/TODO.md

* `temp_del` should only delete things created with `temp_make`
* `temp_make --prefix` doesn't work?

* Port some of my register teardown magic
* Better error reporting hooks.  Sometimes stderr is given when a test fails sometimes it isn't, provide a mechanism for reporting errors so they're all displayed when a failure occurs.
* Some evidence of cleanup failures...
* Print (optionally) saved command output on failure.  Alternatively at least give the saved command output file so the user can see it.
* Ability to add custom messages to the output of failed assertions.
* `expect_*` to match all of the `assert_*` functions.  Report the error and fail the test, but don't exit immediately
* `assert_output` to take an argument per line and additionally assert number of lines of output is a no-brainer.  (Or maybe a differently named assertion to preserve backwards compatibility.)  (Port `assert_all_lines` and associated tests from utils.sh)

* `fail` (and presumably `assert`?) commands don't fail tests when called from setup/teardown?
* `fail` (via `batslib_err`) don't handle escape characters in arguments, should print with `echo -e`.
* `assert_output` and `assert_line` should quote expected and actual output when printing so we can see whitespace differences.

* Ability to run single test from a bats file.  Maybe `bats file.bats:<test number>`?  Might also need a --list feature to determine the test numbers.
* Ability to run tests in random order (to ensure no state is carried over.)  Can this work with the above feature?  If so how?
* Report summary of tests passed, failed, and skipped.  Also report per fixture/file.  Maybe needs a --verbose flag (or a few --verbose flag levels.)
* Report timing results and per suite timing results.
* `fail` (via `batslib_err`) don't handle escape characters in arguments, should print with `echo -e`.
* `assert_output` and `assert_line` should quote expected and actual output when printing so we can see whitespace differences.
* Ability to add custom messages to the output of failed assertions.
* Some evidence of cleanup failures...
* `run` in directory?
* Debug mode where we (optionally, run a single test and) see the output for all the commands.  Optionally run test with -x (but not seeing all the bats hooks?).
Found some bugs...

* Clean-up.  If a test fails or is killed or unstub is not call for some reason, plan and run files persist and are picked up/added to next time, causing spurious failures.
* `unstub` (and maybe `stub`) don't work when called from setup/teardown.
* Error reporting.  Stubbing can cause a test to fail in several places, the default error report is not particularly useful.  We can't echo errors at the time they occur because we might be inside a bats `run()` call.  Therefore we should save error reports and print them as part of the unstub.
* The fact that `binstub` is something of a god object is a bit shit, some refactoring of the code could make it easier to follow perhaps.
* Whitespace in expectations causes arguments to not match.  See dot-files/tests/bin/test_dev-push-all.bats; ssh stub doesn't work, perhaps args args are too complex?
* Wildcard argument expectations.  Actually this works?  Add tests for it and add it to the documentation either way.
* No ability to mock out an executable and expect it NOT to be called.  A-la gtest's `.Times(0)` or similar.  Intuatively, `stub prog.exe` without any expectation arguments should do that.  More generally, how about the ability to match an expectation multiple times?
* Fall back execution.  On non-matching call to mocked process, fall back to calling underlying executable.
