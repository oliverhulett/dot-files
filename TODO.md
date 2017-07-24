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
* ssh.sh hard-codes cloning from optiver repo, be smarter about that.  Since ssh.sh is checked in, can we discover and use 'origin'?  What if we're SSH-ing from a machine where ssh.sh is a copy not a checkout (but to a machine where we could clone dot-files?)
* Docker/drone the tests to run on a Centos7 image, a Centos5 image, and a few Ubuntu images.
    * Make sure tests run against working directory of dot-files, not against installed version.
* Organise all the files better.
* Discovery mechanism for including environment setups.
    * Sourcing .../09-env-proxy.sh is a common pattern in scripts that need to fetch stuff from the internet.  But they don't all do it in the same way (e.g. some source ${HOME}/.bash_aliases/... and some source $(dirname "${BASH_SOURCE[0]}")/bash_aliases)  Is there a "correct" way (testability) or should it depend on what they're doing?
    * Is there an easier way of including these bits that will provide a central place to update if we move the files?  Or should be just be testing file location?
    * Whatever it is has to work for scripts launched by a fully setup bash prompt and from a "clean" environment.

* Test/Task/CI idea
    * Start with a directory hierarcy.
    * Sibling directories are run in parallel.
    * Each directory is run before its children.
    * All execution happens in a sandboxed temporary directory.  Handle marshalling and copying.
    * Child directory tasks inherit context/artifacts from parent tasks/directories.
    * A task is a *.m4 file that is parsed and output into the run dir
        * Help by defining macros that create a small DSL and handle pathing...
        * Enforce order of steps to guarantee scoping.
        * Hooks for various steps:
            * init, stage, setup, run, teardown, validate...
            * By function name or file name
    *
* Maybe try/test the idea with the dotfiles tests?
* Should be a stand alone project (can test itself with itself)

* Git:  Organise wrappers better and test them
    * Instead of wrappers called from aliases, make them commands (`git-*` style) and wrap git to add them to the path.
        * Git executable becomes wrapper in bin/ that sets PATH and calls git.
        * Executables for git functionality in git-things/bin.
        * Git "aliases" become symlinks or (wrappers with default args/arg handling and help) to executables in git-things/bin/.
        * How to do command line completion?
        * How to do man pages? - in a dodgy dodgy way...
    * Group things better:  branch management, externals management, resolution helpers, cleaning, pulling, refs and discovery?
    * merge and branch help, don't merge til changelog is updated.
    * Add a command to rebase all from master.
    * Pattern for overwriting builtin command should be a suffix with 'me'.  Get it in the fingers, keep the rest of the interface the same and hopefully the git typo heuristic does the rest.
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

* Bash mechanism of one-shot commands and idempotent commands.
    * Want something in the bash prompt, or similar, that provides a way to set some machine state.  It'll need to be idempontent, i.e. check for state, perform action of state is not correct.  The check for state has to be super fast if its going to happen on every prompt.  Alternatively, remove the command after successful execution.
    * Should be useful for (among others):
        * python_setup
        * "Vagrant" installs
        * Tab completion/Program specific environment magic
            * I'm thinking of a way to "automagically" install tab-completion and other program specific environment magic on first use of a program.  Basically, on first execution, look for some program specific setup in .bash_something and execute/source it.
            * Tab completion, at least, may best be hooked into the global tab completion mechanism, if that is possible.

* Data conceptualisation idea
    * Define "data types" (loosely, just a name/index and a version)
    * Each "data type" has:
        * Add(data) which adds/merges data into an index.  This either finds a matching instance to which it should add data or creates a new one.
        * Delete(data) which deletes the instances in the index with matching fields.
        * Fetch(data) which returns the instances in the index that have matching fields.
    * Processors use Add() and Delete(), consumers use Fetch()
    * All the functions on "data types" must be idempotent.
        * Want to be able to replay data from any point without breaking data quality of "derived" "data types"
        * Want to be able to replay data from any point with relatively low overhead.
        * Want to be able to push Updates/Additions(/Deletions?) of "data types" back into processors without creating infinate loops. (Will need good reporting on that sort of thing)
        * Want to be able to artificially play a "data type" through the processors when we've added new "data types" or processors
            * Create a new "data type" by (setting up "data type" and processor and) having processors send data to it.
            * Updating a schema (version) is a special case of this?
    * Data is just key/value pairs (nested? basically that'd be JSON)
    * Incoming data is given to a set of processors, which use above functions to add it to an index.
    * Updates/Additions to existing indicies ("data type" instances) are fed back into the set of processors.  If Add()/Delete() doesn't make a change, nothing is routed back to the processors.
    * Add()/Detele() functions on "data types" should be quick to drop data in which they're not interested.
    * The idea is that processors are basically routers from incoming data to "data types"
    * Conflict resolution...?
        * What if a "data type" can't handle incoming data?
        * What if a "data type" can't find a match for incoming data?
        * What if Add()/Delete() reports an error?
        * Need some mechanism for reporting these.
        * Want ability to install conflict handlers?  Are these just processors?  Conflicts are another form of "incoming" data?
    * Processors should be able to drop their inputs.
    * Processors get all new data type instances, so they should be able to alert external systems and then drop the new instances.
* Which of Logstash/MongoDB/Splunk/other? best fits this model, can be massaged into this model with some simple wrapping?
* Should be a stand alone project
* Try to test the idea with dotlogs data
    * For Optiver purposes, incoming data would be log files and/or ticks.
* Additional concept:
    * Ability (dockerised?) to setup a stack, pull a filtered section of the data from the cluster, work with it, optionally sync changes back.
    * Can build the feature by making standard tasks easy:
        * Stack setup, dockerised version plus easy setup.  Seperate from connecting a stack to a cluster and adding data.
        * Pulling filtered sections of data into a stack.  Make that a input type, so just give it to the processors.
        * Pushing data to a cluster.  Is that just the reverse of the above?  Is it valueable or do we just install new processors into the cluster and let them recreate the new data?
        * Connecting a stack to an existing cluster.  Rules for handling data duplication and additions/deletions/changes to data and reindexing.
