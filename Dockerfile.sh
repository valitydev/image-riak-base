#!/bin/sh
cat <<EOF
FROM ${REGISTRY}/${ORG_NAME}/build:${BUILD_IMAGE_TAG} as build
RUN rm /etc/portage/repos.conf/*.conf
COPY files/portage/ /etc/portage
COPY portage/ /usr/portage
COPY overlays/ /var/lib/layman

# Set portage root and install stuff


RUN export ROOT=/tmp/portage-root \
    && mkdir -p /tmp/portage-root/etc/ \
    && echo 'Europe/Moscow' > /tmp/portage-root/etc/timezone \
    && emerge --getbinpkgonly glibc coreutils sys-libs/timezone-data \
    && emerge sys-libs/zlib openssl sys-apps/sed sys-apps/grep sys-apps/gawk net-misc/curl iproute2 bash \
    dev-libs/elfutils
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
