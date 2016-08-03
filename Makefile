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
	cd $(BASE_DIR)/$(dir $@) && $(PACKER) build packer.json && touch .state

bootstrap/packer.json: bootstrap/packer.json.template
	sed -e 's:<PATH>:$(BASE_DIR):g' -e 's:<SHARED>:$(IMAGES_SHARED):g' $< > $@

push:
	$(DOCKER) tag "$(DREPO)/bootstrap" "$(DREPO)/bootstrap:$(shell date --rfc-3339=date)"
	$(DOCKER) push "$(DREPO)/bootstrap:$(shell date --rfc-3339=date)"
