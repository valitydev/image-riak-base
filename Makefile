SERVICE_NAME := embedded
UTILS_PATH := build-utils

.PHONY: $(SERVICE_NAME) push submodules repos update-latest-stage3
$(SERVICE_NAME): .state

-include $(UTILS_PATH)/make_lib/utils_repo.mk
PACKER := $(shell which packer 2>/dev/null)

COMMIT := $(shell git rev-parse HEAD)
TAG := $(COMMIT)
rev = $(shell git rev-parse --abbrev-ref HEAD)
BRANCH := $(shell \
if [[ "${rev}" != "HEAD" ]]; then \
	echo "${rev}" ; \
elif [ -n "${BRANCH_NAME}" ]; then \
	echo "${BRANCH_NAME}"; \
else \
	echo `git name-rev --name-only HEAD`; \
fi)

SUBMODULES = $(UTILS_PATH)
SUBTARGETS = $(patsubst %,%/.git,$(SUBMODULES))
REPOS = portage
REPOS_TARGET = $(patsubst %,$(IMAGES_SHARED)/%/.git,$(REPOS))

$(SUBTARGETS):
	$(eval SSH_PRIVKEY := $(shell echo $(GITHUB_PRIVKEY) | sed -e 's|%|%%|g'))
	GIT_SSH_COMMAND="$(shell which ssh) -o StrictHostKeyChecking=no -o User=git `[ -n '$(SSH_PRIVKEY)' ] && echo -o IdentityFile='$(SSH_PRIVKEY)'`" \
	git submodule update --init $(subst /,,$(basename $@))
	touch $@

submodules: $(SUBTARGETS)

repos: $(REPOS_TARGET)

Dockerfile: Dockerfile.sh
	SERVICE_NAME=$(SERVICE_NAME) BRANCH=$(BRANCH) COMMIT=$(COMMIT) ./Dockerfile.sh > Dockerfile

.state: $(PACKER) $(REPOS_TARGET) packer.json files/packer.sh files/portage.make.conf Dockerfile
	mkdir -p portage-root
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	# XXX w/o sudo suided files cause ENOPERM when sending build conext to
	# docker
	sudo docker build -t $(SERVICE_IMAGE_NAME):$(TAG) .
	echo $(TAG) > $@


test:
	$(DOCKER) run "$(SERVICE_IMAGE_NAME):$(shell cat .state)" \
	bash -c "python --version"

push:
	$(DOCKER) push "$(SERVICE_IMAGE_NAME):$(shell cat .state)"

clean:
	test -f .state \
	&& $(DOCKER) rmi -f "$(SERVICE_IMAGE_NAME):$(shell cat .state)" \
	&& rm .state  \
	&& rm -rf portage-root

