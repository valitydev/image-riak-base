#!/bin/sh
cat <<EOF
FROM ${REGISTRY}/${ORG_NAME}/build:${BUILD_IMAGE_TAG} as build
RUN rm /etc/portage/repos.conf/*.conf
COPY files/portage/ /etc/portage
COPY portage/ /usr/portage
COPY overlays/ /var/lib/layman

# Set portage root and install stuff
ENV ROOT=/tmp/portage-root
RUN emerge --getbinpkgonly glibc coreutils
RUN emerge coreutils sed grep gawk attr net-misc/curl openssl iproute2 bash
# Install logger stub to avoid installing util-linux
COPY files/logger /tmp/portage-root/usr/bin/logger

# TODO: more cleanup
RUN rm -rf $ROOT/var/cache/edb/*

FROM scratch 
COPY --from=build /tmp/portage-root/ /
LABEL com.rbkmoney.${SERVICE_NAME}.parent=null \
    com.rbkmoney.${SERVICE_NAME}.parent_tag=null  \
    com.rbkmoney.${SERVICE_NAME}.branch=${BRANCH}  \
    com.rbkmoney.${SERVICE_NAME}.commit_id=${COMMIT}  \
    com.rbkmoney.${SERVICE_NAME}.commit_number=`git rev-list --count HEAD`
EOF
