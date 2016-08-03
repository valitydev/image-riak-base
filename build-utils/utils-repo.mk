REPO_INIT := build-utils/repo_init.sh
IMAGES_SHARED := $(shell echo "${HOME}")/.cache/rbkmoney/images/shared
GITHUB_PRIVKEY ?=
GITHUB_URI_PREFIX := git+ssh://github.com

BAKKA_SU_PRIVKEY ?=
BAKKA_SU_PRIVKEY := $(shell echo $(GITHUB_PRIVKEY) | sed -e 's|%|%%|g')
BAKKA_SU_URI_PREFIX := $(if $(BAKKA_SU_PRIVKEY),git+ssh,git)://git.bakka.su

# portage
$(IMAGES_SHARED)/portage/.git: .git
	$(if $(BAKKA_SU_PRIVKEY),SSH_PRIVKEY="$(BAKKA_SU_PRIVKEY)",) "$(REPO_INIT)" \
	"$(IMAGES_SHARED)/portage" "$(BAKKA_SU_URI_PREFIX)/gentoo-mirror"

# overlays
$(IMAGES_SHARED)/overlays/rbkmoney/.git: .git
	$(if $(GITHUB_PRIVKEY),SSH_PRIVKEY="$(GITHUB_PRIVKEY)",) "$(REPO_INIT)" \
	"$(IMAGES_SHARED)/overlays/rbkmoney" "$(GITHUB_URI_PREFIX)/rbkmoney/gentoo-overlay"

$(IMAGES_SHARED)/overlays/baka-bakka/.git: .git
	$(if $(BAKKA_SU_PRIVKEY),SSH_PRIVKEY="$(BAKKA_SU_PRIVKEY)",) "$(REPO_INIT)" \
	"$(IMAGES_SHARED)/overlays/baka-bakka" "$(BAKKA_SU_URI_PREFIX)/baka-bakka"

# salt
$(IMAGES_SHARED)/salt/rbkmoney/.git: .git
	$(if $(GITHUB_PRIVKEY),SSH_PRIVKEY="$(GITHUB_PRIVKEY)",) "$(REPO_INIT)" \
	"$(IMAGES_SHARED)/salt/rbkmoney" "$(GITHUB_URI_PREFIX)/rbkmoney/salt-main"

$(IMAGES_SHARED)/salt/common/.git: .git
	$(if $(BAKKA_SU_PRIVKEY),SSH_PRIVKEY="$(BAKKA_SU_PRIVKEY)",) "$(REPO_INIT)" \
	"$(IMAGES_SHARED)/salt/common" "$(BAKKA_SU_URI_PREFIX)/salt-common"
