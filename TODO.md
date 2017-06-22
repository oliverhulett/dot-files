This is just a random assortment of TODO thoughts.  For more detailed TODOs, see the files in the `todo/` directory.

* Add README.md and CHANGELOG.md.
* Create TODO format and helpers for adding TODOs in that format.
* TODO cmd to add to this ad-hoc todo list.
* Consolidate all of the TODOs, they're too hard to keep track of when distributed.
    * Also, organise them in some way.
* Some way of synchronising TODOs (and README/CHANGELOG?) across all branches?  Do we really want this, or do we want it in master only?
* Alternatively, some sort of per feature TODO mechanism/format.  Can update and add feature TODO lists, there is 1 TODO list to 1 feature branch.
    * Master has them all?
    * Merging back to master removes that feature's TODO (or that feature should have removed it before merging?)
    * Can create a feature branch from a TODO feature.
* Want to be able to add to TODOs from any checkout and sync them so they can be read from any checkout (and any remote).

* What is wrong with my colours on Ubuntu?
* Docker/drone the tests to run on a Centos7 image, a Centos5 image, and a few Ubuntu images.
    * Make sure tests run against working directory of dot-files, not against installed version.
* Organise all the files better.

* Test/Task/CI idea
    * Start with a directory hierarcy.
    * Sibling directories are run in parallel.
    * Each directory is run before its children.
    * All execution happens in a sandboxed temporary directory.  Handle marshalling and copying.)
    * Child directory tasks inherit context/artifacts from parent tasks/directories.
    * A task is a Dockerfile that is built and run.
        * We want some way to inherit the parent's docker image so we can build off it and run in the same context.
        * A task is also a Makefile (following a contract) that builds the Dockerfile/image.  In that case why not just have the Makefile run the task?
        * Or, a task is just an executable to run (a known name?) users can docker if they want, or whatever.
* Maybe try/test the idea with the dotfiles tests?
* Should be a stand alone project (can test itself with itself)

* Git:  Organise wrapper better and test them
    * Instead of wrappers called from aliases, make them commands (`git-*` style) and wrap git to add them to the path.
        * Git executable becomes wrapper in bin/ that sets PATH and calls git.
        * Executables for git functionality in bin/git-bin.
        * Git "aliases" become symlinks or (wrappers with default args/arg handling and help) to executables in git-bin/.
        * How to do command line completion?
        * How to do man pages?
    * Group things better:  branch management, externals management, resolution helpers, cleaning, pulling, refs and discovery?
    * merge and branch help, don't merge til changelog is updated.
    * Add a command to rebase all from master.
    * Update git-which to work with git-bin.
    * Fix following two things also, with tests.
* Git pull with sync-other-remote.  Pull does a merge that has conflicts as it replays sync-other-remote commits.  Is the answer just to push first?  So we should push from the sync-other-remote script?
* I had an idea about creating git feature branches...  Create a todo/task list for the feature branch that gets turned into changelog details.  Wrap feature branch creation and merging to create todo/task list and merge into changelog.  Basically enforce/helpers for git workflow built into the branch/merge commands.

* Plan vim plugin.  Stand alone project (make a new one)
* Vim tip-of-the-day style thing.  Use the `<leader>/` `Cheat40` plugin to help me learn Vim.
    * Start with `Cheat40` open (but not focussed, change the focus/dismiss helper message at the top to indicate how to get rid of it when it's not focussed.).
    * Dynamically assign a random hint or tip to be shown at the top of the help window.
    * Add the shortcut (`<leader>/`) as a hint in the status bar.
    * Add cheat40 lists and custom help
    * Create hint of the day plugin.  Turn into context aware hint plugin.
    * Maybe add help helpers to cheat40 plugin.
* Where has my spelling highlighting gone in Vim?
* Why aren't vimrc changes synced from work to home?
* Vim: last command persists in the command line, can I make it decay or change colour or something when the command finishes?
* Vim: Sort out custom mappings.  Window navigation, quick-list and location-list usage and navigation, spelling and syntax error navigation...
* Vim: Markdown syntax nests lists by default, very annoying.
* Vim: Change auto-complete shortcut from `<C-P>` to `<leader><Tab>` or something easy like that.
* Vim: Flash new cursor position on jump.
* Vim: Highlight focussed window.
* Vim: Command/shortcut to add to help/`Cheat40` list.  Helps, prompts, or automates formatting and fields.
* Vim: Does double duty for me as a light-weight code editor and a general purpose text/configuration file editor.

* Crontab tests and better organisation of those tasks.
    * Setup as discussed in notes
    * How to have dependent/ordered tasks?
* General: Is it possible to have core files named to include their timestamp, rather than just process ID?
* less: Stay in less on short files, but also keep short files on screen after exit?  Do I still want that one?
* Colourise (pygmentise) `cat`, `head`, and `tail` output.  Need flag to disable?  detect output?
* Fix less at home, grr
* Fix less follow with `lessfilter` (or is it just `colourise.py`?)
* `stasher.py` force cache refresh with cmdline flag.  (Or are we happy to just find and remove temp file?)
