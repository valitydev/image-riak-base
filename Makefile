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
	$(eval COMMIT := $(shell git rev-parse HEAD))
	$(eval TAG := $(shell date +%s)-$(COMMIT))
	$(eval BRANCH := $(shell \
	if [[ "HEAD" != $(git rev-parse --abbrev-ref HEAD) ]]; then \
		echo $(git rev-parse --abbrev-ref HEAD); \
        elif [ -n "$BRANCH_NAME" ]; then \
		echo $BRANCH_NAME; \
        else \
		echo $(git name-rev --name-only HEAD); \
        fi))
	$(eval STAGE3 := $(shell cat .latest-stage3))
	$(DOCKER) run -v `pwd`:/tmp/pwd -w /tmp/repack busybox /bin/sh -c \
	"tar xjf /tmp/pwd/$(STAGE3); tar cjf /tmp/pwd/$(STAGE3).repack ."
	$(DOCKER) import $(STAGE3).repack "$(REGISTRY)/$(ORG_NAME)/stage3-amd64-hardened-nomultilib"
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	printf "FROM $(SERVICE_IMAGE_NAME):$(TAG)\n \
	LABEL com.rbkmoney.$(SERVICE_NAME).parent=null \
	com.rbkmoney.$(SERVICE_NAME).stage3-used=$(STAGE3) \
	com.rbkmoney.$(SERVICE_NAME).branch=$(BRANCH) \
	com.rbkmoney.$(SERVICE_NAME).commit_id=$(COMMIT) \
	com.rbkmoney.$(SERVICE_NAME).commit_number=`git rev-list --count HEAD`" \
	| docker build -t $(SERVICE_IMAGE_NAME):$(TAG) -
	echo $(TAG) > $@

test:
	$(DOCKER) run "$(SERVICE_IMAGE_NAME):$(shell cat .state)" \
	bash -c "salt --versions-report; ssh -V"

push:
	$(DOCKER) push "$(SERVICE_IMAGE_NAME):$(shell cat .state)"
