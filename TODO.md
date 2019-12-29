This is just a random assortment of TODO thoughts.  For more detailed TODOs, see the files in the `todo/` directory.

* Add README.md and CHANGELOG.md.
* Docker/drone the tests to run on a Centos7 image, a Centos5 image, and a few Ubuntu images.
* Organise all the files better.
* Come up with a mechanism for combining list files where lists are needed but need to be different between machines.
    * I'm thinking a naming or directory heirarchy that won't be too dissimilar to the Test/Task/CI idea.  Therefore also a tool/tools to view the heirarchy and show resolutions for various inputs.
* Discovery mechanism for including environment setups.
    * Sourcing .../09-env-proxy.sh is a common pattern in scripts that need to fetch stuff from the internet.  But they don't all do it in the same way (e.g. some source ${HOME}/.bash-aliases/... and some source $(dirname "${BASH_SOURCE[0]}")/bash-aliases)  Is there a "correct" way (testability) or should it depend on what they're doing?
    * Is there an easier way of including these bits that will provide a central place to update if we move the files?  Or should be just be testing file location?
    * Whatever it is has to work for scripts launched by a fully setup bash prompt and from a "clean" environment.
    * `source` looks in $PATH if the file to source has no slashes in it.  Put bash-common.sh in path, source it to fetch a `source` wrapper that knows about ~/.bash-aliases and dot-files (maybe two wrappers)

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

* Plan vim plugin.  Stand alone project (make a new one)
* Vim tip-of-the-day style thing.  Use the `<leader>/` `Cheat40` plugin to help me learn Vim.
    * Start with `Cheat40` open (but not focussed, change the focus/dismiss helper message at the top to indicate how to get rid of it when it's not focussed.).
    * Dynamically assign a random hint or tip to be shown at the top of the help window.
    * Add the shortcut (`<leader>/`) as a hint in the status bar.
    * Add cheat40 lists and custom help
    * Create hint of the day plugin.  Turn into context aware hint plugin.
    * Maybe add help helpers to cheat40 plugin.
* Where has my spelling highlighting gone in Vim?
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
* less: Stay in less on short files, but also keep short files on screen after exit?  Do I still want that one?  Look at combinations of -X and -F.
* Colourise (pygmentise) `cat`, `head`, and `tail` output.  Need flag to disable?  detect output?
* Fix less follow with `lessfilter` (or is it just `colourise.py`?)

* Bash mechanism of one-shot commands and idempotent commands.
    * Want something in the bash prompt, or similar, that provides a way to set some machine state.  It'll need to be idempontent, i.e. check for state, perform action of state is not correct.  The check for state has to be super fast if its going to happen on every prompt.  Alternatively, remove the command after successful execution.
    * Should be useful for (among others):
        * python_setup
        * "Vagrant" installs
        * Tab completion/Program specific environment magic
            * I'm thinking of a way to "automagically" install tab-completion and other program specific environment magic on first use of a program.  Basically, on first execution, look for some program specific setup in .bash_something and execute/source it.
            * Tab completion, at least, may best be hooked into the global tab completion mechanism, if that is possible.
* Need to worry about re-entrance/concurrent execution.  Especially, test setup-home.sh concurrent execution...
