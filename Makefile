include build-utils/utils-image.mk
include build-utils/utils-repo.mk
PACKER := $(shell which packer 2>/dev/null || echo ./packer)
BASE_DIR := $(shell pwd)

DOCKER := $(shell which docker 2>/dev/null)

PULL := true

.PHONY: bootstrap push

# bootstrap
bootstrap: bootstrap/.state

bootstrap/.state: $(PACKER) $(IMAGES_SHARED)/portage/.git bootstrap/packer.json bootstrap/packer.sh bootstrap/portage.make.conf
	$(PACKER) build -var 'base-path=$(BASE_DIR)' \
	-var 'image-tag=$(shell date --rfc-3339=date)' packer.json \
	&& touch $@

push:
	$(DOCKER) push "$(DREPO)/bootstrap:$(shell date --rfc-3339=date)"
