PACKER := $(shell which packer 2>/dev/null || which ./packer)
PCONF  := packer.json
PBUILD := $(PACKER) build $(PCONF)
BASE_DIR := $(shell pwd)

DOCKER := $(shell which docker 2>/dev/null)
DREPO  := dr.rbkmoney.com/rbkmoney
CONTAINER ?=

BAKKA_SU_PRIVKEY ?=
BAKKA_SU_URI_PREFIX := $(if $(BAKKA_SU_PRIVKEY),git+ssh,git)://git.bakka.su
BAKKA_SU_SSH_COMMAND := $(shell which ssh) -o User=git -o StrictHostKeyChecking=no $(if $(BAKKA_SU_PRIVKEY),-i $(BAKKA_SU_PRIVKEY),)


.PHONY: bootstrap push 

# portage
shared/portage/.git/config:
	rm -rf "$(BASE_DIR)/shared/portage" \
	&& GIT_SSH_COMMAND="$(BAKKA_SU_SSH_COMMAND)" git clone \
	"$(BAKKA_SU_URI_PREFIX)/gentoo-mirror" --depth 1 \
	"$(BASE_DIR)/shared/portage"

# overlays
shared/baka-bakka/.git/config:
	rm -rf "$(BASE_DIR)/shared/baka-bakka" \
	&& GIT_SSH_COMMAND="$(BAKKA_SU_SSH_COMMAND)" git clone \
	"$(BAKKA_SU_URI_PREFIX)/baka-bakka" --depth 1 \
	"$(BASE_DIR)/shared/baka-bakka"

# bootstrap
bootstrap: bootstrap/.state

bootstrap/.state: $(PACKER) shared/portage/.git/config bootstrap/packer.json bootstrap/packer.sh bootstrap/portage.make.conf
	cd $(BASE_DIR)/$(dir $@) && $(PBUILD) && touch .state

bootstrap/packer.json: bootstrap/packer.json.template
	sed 's:<PATH>:$(BASE_DIR):g' $< > $@


# docker push
# make sure to run `docker login` before
push: $(CONTAINER)/.state $(DOCKER) ~/.docker/config.json
	$(DOCKER) push $(DREPO)/$(CONTAINER)


~/.docker/config.json:
	test -f ~/.docker/config.json || (echo "Please run: docker login" ; exit 1)
