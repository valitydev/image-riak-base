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
	UTILS_PATH="$(UTILS_PATH)" \
	build-utils/sh/getstage3.sh amd64 -hardened+nomultilib | tail -n 1 > $@

.state: .latest-stage3 $(PACKER) $(REPOS_TARGET) packer.json files/packer.sh files/portage.make.conf
	$(eval TAG := $(shell date +%s)-$(shell git rev-parse HEAD))
	$(eval STAGE3 := $(shell cat .latest-stage3))
	$(DOCKER) run -v `pwd`:/tmp/pwd busybox /bin/sh -c \
	-w /tmp/repack "tar xjf /tmp/pwd/$(STAGE3); tar cjf /tmp/pwd/$(STAGE3).repack ."
	$(DOCKER) import $(STAGE3).repack "$(REGISTRY)/$(ORG_NAME)/stage3-amd64-hardened-nomultilib"
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	printf "FROM $(REGISTRY)/$(ORG_NAME)/bootstrap:$(TAG)\n \
	LABEL com.rbkmoney.bootstrap.stage3-used=$(STAGE3) \
	com.rbkmoney.bootstrap.parent=null \
	com.rbkmoney.bootstrap.branch=`git name-rev --name-only HEAD` \
	com.rbkmoney.bootstrap.commit=`git rev-parse HEAD`" \
	| docker build -t $(REGISTRY)/$(ORG_NAME)/bootstrap:$(TAG) -
	echo $(TAG) > $@

test:
	$(DOCKER) run "$(REGISTRY)/$(ORG_NAME)/$(SERVICE_NAME):$(shell cat .state)" \
	bash -c "salt --versions-report; ssh -V"

push:
	$(DOCKER) push "$(REGISTRY)/$(ORG_NAME)/$(SERVICE_NAME):$(shell cat .state)"
