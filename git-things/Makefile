# Create simple man pages from the --help output of custom git commands.

GIT_CMDS := $(wildcard bin/git-*)
MAN_FILES := $(addsuffix .1.gz, $(addprefix man/man1/, $(notdir $(GIT_CMDS))))
TARGETS := $(notdir $(GIT_CMDS))

help:   ## Display this help message
	@echo "Makefile to create simple man pages from the --help output of custom git commands."
	@echo
	@echo "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
	@echo "  Available targets: $(TARGETS)"

.PHONY: help all $(TARGETS)

bin/%:	## Create a new script from a template
	cp .template.sh $@
	chmod +x $@
	git add $@


all:	## Build all man pages
all: $(MAN_FILES)


$(TARGETS):	## Build single man file
$(TARGETS):%: man/man1/%.1.gz


man/man1/%.1.gz: bin/%
	@mkdir --parents man/man1
	$< --help | gzip -c >$@
	git add $@
