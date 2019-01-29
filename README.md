# dot-files

Local environment setup.  No secrets committed, so it should be safe to fork and use/modify for yourself, so feel free.
Please drop my a line if you see anything you like or if you make any changes or improvements.

Run `./setup-home.sh` to link from your checkout into your home directory.

The resulting bash environment (when sourcing ~/.bashrc) requires some things to be installed.  What exactly needs to be installed is not (yet) documented.  However, I recently had reason to use a Mac (work) my local environment failed badly.  This is predicable, given the lack of most of the GNU tools on Macs by default.  Homebrew solves almost everything, but reminds me that there is some machine setup required for this project that should be documented, or better still automated.

For lack of anything better to start with, this is me attempting to use this on the Mac:

```
$ BREWINSTALLER=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install) &&
    ruby -e "$BREWINSTALLER" || echo "Failed to install brew :("
$ brew update
$ brew tap homebrew/dupes
$ brew install --with-default-names gnu-getopt gnu-indent gnu-sed gnu-tar gnutls gnu-time gnu-which grep gawk bash-completion
$ brew link --force gnu-getopt
$ python <(curl https://bootstrap.pypa.io/get-pip.py)
```

And, of course, use [iTerm|https://www.iterm2.com/downloads.html] on the Mac.
