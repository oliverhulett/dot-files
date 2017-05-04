NAME := docker-registry.aus.optiver.com/olihul/dot-files

GITREF := $(shell git log --pretty=format:"%h" -1)
GITREPO := $(shell git config --get remote.origin.url)
BUILDUSER := $(shell whoami)
BUILDNUMBER := $(shell echo $${bamboo_buildNumber:=NON_CI_BUILD})
CHANGEDFILES := $(shell git status --porcelain | wc -l)

MARKERFILE := .created

.PHONY: help build pull push release clean

help:	## Display this help message
	@echo -e "Makefile to build a docker image.  This image will be called $(NAME)"
	@echo
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

build:	## Build the docker image
build: CMD = docker build \
		--build-arg=HTTP_PROXY=$(HTTP_PROXY) \
		--build-arg=HTTPS_PROXY=$(HTTPS_PROXY) \
		--build-arg=NO_PROXY=$(NO_PROXY) \
		--build-arg=http_proxy=$(http_proxy) \
		--build-arg=https_proxy=$(https_proxy) \
		--build-arg=no_proxy=$(no_proxy) \
		--build-arg=GIT_REV="$(GITREF)" \
		--build-arg=GIT_REPO="$(GITREPO)" \
		--build-arg=BUILD_USER="$(BUILDUSER)" \
		--build-arg=BUILD_NUMBER="$(BUILDNUMBER)" \
		--build-arg=BUILD_MODIFIED_FILES="$(CHANGEDFILES)" \
		-t $(NAME) .
build: $(MARKERFILE)

pull:	## Pull the latest version of the docker image
pull: CMD = docker pull $(NAME)
pull: $(MARKERFILE)

push:	## Push the current version of the docker image if there are no modified files
	docker inspect $(NAME) | grep '"build_modified_files": "0"' >/dev/null || (echo "The image was build from a dirty GIT repo" ; exit 1)
	echo "Pushing Image to Registry"
	docker tag $(NAME) $(NAME):$(GITREF)
	docker push $(NAME)
	docker push $(NAME):$(GITREF)

release:	## Build and push the docker image
release: build push

clean:	## Remove this version of the docker image
	test -z "$$(docker images -q $(NAME):latest)" || docker rmi -f $(NAME)
	test -z "$$(docker images -q $(NAME):$(GITREF))" || docker rmi -f $(NAME):$(GITREF)
	test ! -f $(MARKERFILE) || rm $(MARKERFILE)

$(MARKERFILE): Dockerfile
	$(CMD)
	@WHEN=$$(docker inspect -f '{{ .Created }}' $(NAME)); \
	if [ -n "$${WHEN}" ]; then \
		echo "$${WHEN}" >$@; \
		touch --date="$${WHEN}" $@; \
	fi

FORCE:

DOCKERRUN_FILE := .docker
DOCKERME_CMD := dockerme

$(DOCKERRUN_FILE): Makefile
	@cat >$(DOCKERRUN_FILE) <<-EOF
		#!/bin/bash
		( cd "$$(dirname "$$0")" && make $(DOCKERRUN_FILE) )
		"$$(dirname "$$0")/$(DOCKERRUN_FILE)" "$$@"
	EOF
