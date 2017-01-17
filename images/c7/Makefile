NAME := docker-registry.aus.optiver.com/olihul/dot-files

GITREF := $(shell git log --pretty=format:"%h" -1)
GITREPO := $(shell git config --get remote.origin.url)
BUILDUSER := $(shell whoami)
BUILDNUMBER := $(shell echo $${bamboo_buildNumber:=NON_CI_BUILD})
CHANGEDFILES := $(shell git status --porcelain | wc -l)

default: build

build:
	docker build \
		--build-arg=HTTP_PROXY=$(http_proxy) \
		--build-arg=HTTPS_PROXY=$(https_proxy) \
		--build-arg=NO_PROXY=$(no_proxy) \
		--build-arg=http_proxy=$(http_proxy) \
		--build-arg=https_proxy=$(https_proxy) \
		--build-arg=no_proxy=$(no_proxy) \
		--build-arg=GIT_REV="$(GITREF)" \
		--build-arg=GIT_REPO="$(GITREPO)" \
		--build-arg=BUILD_USER="$(BUILDUSER)" \
		--build-arg=BUILD_NUMBER="$(BUILDNUMBER)" \
		--build-arg=BUILD_MODIFIED_FILES="$(CHANGEDFILES)" \
		-t $(NAME) .

push:
	docker inspect $(NAME) | grep '"build_modified_files": "0"' > /dev/null || (echo "The image was build from a dirty GIT repo" ; exit 1) 
	echo "Pushing Image to Registry"
	docker tag $(NAME) $(NAME):$(GITREF)
	docker push $(NAME)
	docker push $(NAME):$(GITREF)

debug:
	docker run \
		-ti \
		--rm \
		-e http_proxy=$(http_proxy) \
		-e https_proxy=$(https_proxy) \
		-u `id -u`:`id -g` \
		-v "/etc/passwd:/etc/passwd:ro" \
		-v "/etc/group:/etc/group:ro" \
		-v $(HOME):$(HOME) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v `pwd`:`pwd` \
		-w `pwd` \
		$(NAME) /bin/bash

run:
	docker run -ti --rm $(NAME)

release: build push

clean:
	@docker rmi -f $(NAME) $(NAME):$(GITREF)
