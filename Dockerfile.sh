#!/bin/sh
cat <<EOF
FROM ${REGISTRY}/${ORG_NAME}/build:${BUILD_IMAGE_TAG} as build

# XXX Fix broken build image (compilation error)
ENV USE="multitarget graphite go"
COPY files/repos.conf.gentoo /etc/portage/repos.conf/gentoo.conf
RUN eix-sync && \
    USE="multitarget graphite go" \
    emerge --backtrack=50 --getbinpkgonly --backtrack=50 glibc binutils binutils-libs gcc && \
    eselect binutils set x86_64-pc-linux-gnu-2.28.1 && \
    gcc-config x86_64-pc-linux-gnu-5.4.0

# Set portage root and install stuff
ENV ROOT=/tmp/portage-root
ENV USE=""
RUN emerge --quiet-build=n --verbose glibc coreutils sed grep gawk attr net-misc/curl openssl iproute2 bash 
# Install logger stub to avoid install util-linux
COPY files/logger /usr/bin/logger

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
