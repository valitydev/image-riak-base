SERVICE_NAME := bootstrap
UTILS_PATH := build-utils

.PHONY: $(SERVICE_NAME) push submodules repos
$(SERVICE_NAME): .state

-include $(UTILS_PATH)/make_lib/utils_repo.mk
PACKER := $(shell which packer 2>/dev/null)
SUBMODULES = build-utils
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

.latest-stage3: build-utils/sh/getstage3.sh .git
	UTILS_PATH="$(UTILS_PATH)" build-utils/sh/getstage3.sh amd64 -hardened+nomultilib | tail -n 1 > .latest-stage3

.state: .latest-stage3 $(PACKER) $(REPOS_TARGET) packer.json files/packer.sh files/portage.make.conf
	$(eval TAG := $(shell date -u +%F))
	$(DOCKER) import `cat .latest-stage3` "$(REGISTRY)/$(ORG_NAME)/stage3-amd64-hardened-nomultilib"
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	printf "FROM $(REGISTRY)/$(ORG_NAME)/bootstrap:$(TAG)\n \
	LABEL com.rbkmoney.stage3-used=`cat .latest-stage3` \
	build_image_tag=null base_image_tag=null \
	branch=`git name-rev --name-only HEAD` commit=`git rev-parse HEAD`" \
	| docker build -t $(REGISTRY)/$(ORG_NAME)/bootstrap:$(TAG) -
	echo $(TAG) > $@


test:
	$(DOCKER) run  "$(REGISTRY)/$(ORG_NAME)/$(SERVICE_NAME):$(shell cat .state)" \
	bash -c "salt --versions-report; ssh -V"

push:
	$(DOCKER) push "$(REGISTRY)/$(ORG_NAME)/$(SERVICE_NAME):$(shell cat .state)"
