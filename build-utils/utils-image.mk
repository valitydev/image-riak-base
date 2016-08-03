DOCKER := $(shell which docker 2>/dev/null)
DREPO  := dr.rbkmoney.com/rbkmoney

DOCKER_SQUASH := $(shell which docker-squash 2>/dev/null || echo ~/.local/bin/docker-squash)

IMAGE_NAME ?=
SRC_TAG ?=
PUSH_TAG ?=

push:
	$(DOCKER) tag "$(IMAGE_NAME):$(SRC_TAG)" "$(IMAGE_NAME):$(PUSH_TAG)"
	$(DOCKER) push "$(IMAGE_NAME):$(PUSH_TAG)"
