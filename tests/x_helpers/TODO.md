Things about bats and bats plugin's that I'd like to fix and/or change...

* Things I've already mentioned in bats-mock/TODO.md
* `temp_del` should only delete things created with `temp_make`
* `temp_make --prefix` doesn't work?
* Port some of my setup/teardown inheritance and pairing magic (once I've written it)
* Better error reporting hooks.  Sometimes stderr is given when a test fails sometimes it isn't, provide a mechanism for reporting errors so they're all displayed when a failure occurs.
* `expect_*` to match all of the `assert_*` functions.  Report the error and fail the test, but don't exit immediately
* Print (optionally) saved command output on failure.  Alternatively at least give the saved command output file so the user can see it.
* `fail` (and presumably `assert`?) commands don't fail tests when called from setup/teardown.
