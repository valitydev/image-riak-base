include build-utils/utils-image.mk
include build-utils/utils-repo.mk
PACKER := $(shell which packer 2>/dev/null)
BASE_DIR := $(shell pwd)

.PHONY: bootstrap push

.DEFAULT: bootstrap

bootstrap: .state

.latest-stage3: build-utils/getstage3.sh
	build-utils/getstage3.sh amd64 -hardened+nomultilib | tail -n 1 > .latest-stage3

.state: .latest-stage3 $(PACKER) $(IMAGES_SHARED)/portage/.git packer.json files/packer.sh files/portage.make.conf
	$(eval TAG := $(shell date -u +%F))
	$(DOCKER) import `cat .latest-stage3` "$(DREPO)/stage3-amd64-hardened-nomultilib"
	$(PACKER) build -var 'image-tag=$(TAG)' packer.json
	echo $(TAG) > $@

push:
	$(DOCKER) push "$(DREPO)/bootstrap:$(shell cat .state)"
