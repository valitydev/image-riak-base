SERVICE_NAME := bootstrap
UTILS_PATH := build-utils
BASE_DIR := $(shell pwd)

.PHONY: $(SERVICE_NAME) push
$(SERVICE_NAME): .state

-include build-utils/make_lib/utils_common.mk
-include build-utils/make_lib/utils-repo.mk
PACKER := $(shell which packer 2>/dev/null)
SUBMODULES = build-utils
SUBTARGETS = $(patsubst %,%/.git,$(SUBMODULES))

$(SUBTARGETS):
	GIT_SSH_COMMAND="$(shell which ssh) -o StrictHostKeyChecking=no -o User=git $(shell [ -n "${GITHUB_PRIVKEY}" ] && echo -o IdentityFile="${GITHUB_PRIVKEY}")" \
	git submodule update --init $(basename $@)
	touch $@

submodules: $(SUBTARGETS)

.latest-stage3: build-utils/sh/getstage3.sh
	UTILS_PATH="$(UTILS_PATH)" build-utils/sh/getstage3.sh amd64 -hardened+nomultilib | tail -n 1 > .latest-stage3

.state: .latest-stage3 $(PACKER) $(IMAGES_SHARED)/portage/.git packer.json files/packer.sh files/portage.make.conf
	$(eval TAG := $(shell date -u +%F))
	$(DOCKER) import `cat .latest-stage3` "$(REGISTRY)/stage3-amd64-hardened-nomultilib"
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	echo $(TAG) > $@

push:
	$(DOCKER) push "$(REGISTRY)/$(SERVICE_NAME):$(shell cat .state)"
